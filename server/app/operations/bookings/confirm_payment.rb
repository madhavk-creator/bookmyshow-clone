# Simulates payment confirmation (no real gateway yet).

# Flow:
#   1. Validate booking is still pending and lock hasn't expired
#   2. Create a Transaction record (simulated)
#   3. Mark Payment as completed
#   4. Transition ShowSeatState rows from locked → booked
#   5. Transition Booking from pending → confirmed

module Bookings
  class ConfirmPayment < Trailblazer::Operation
    step :find_booking
    step :validate_pending
    step :confirm_payment_transactionally
    fail :collect_errors

    def find_booking(ctx, params:, **)
      ctx[:model] = ::Booking.includes(:payments, tickets: {}, show: {}).find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: ['Booking not found'] }
        return false
      end

      true
    end

    def validate_pending(ctx, model:, **)
      unless model.status_pending?
        ctx[:errors] = { base: ["Booking is #{model.status} — cannot confirm payment"] }
        return false
      end

      # Check the lock hasn't already expired
      if ShowSeatState.where(lock_token: model.lock_token, status: 'locked').none?
        ctx[:errors] = { base: ['Booking has expired — seat locks were released'] }
        return false
      end

      true
    end

    def confirm_payment_transactionally(ctx, model:, **)
      payment = model.payments.find_by(status: 'pending')
      unless payment
        ctx[:errors] = { base: ['No pending payment found for this booking'] }
        return false
      end

      expected_locked_count = model.tickets.count
      confirmation_succeeded = false

      ActiveRecord::Base.transaction do
        # Simulated transaction — replace with real gateway ref_no in production
        ::Transaction.create!(
          payment:          payment,
          ref_no:           "SIM-#{SecureRandom.hex(8).upcase}",
          payment_method:   'simulated',
          amount:           payment.amount,
          transaction_time: Time.current,
          status:           'completed'
        )

        payment.update!(status: 'completed', paid_at: Time.current)

        # Transition locked → booked for all seats in this booking.
        # Uses lock_token to find the right rows without relying on booking_id.
        booked_count = ShowSeatState.where(lock_token: model.lock_token, status: 'locked')
                                    .where('locked_until >= ?', Time.current)
                                    .update_all(status: 'booked', locked_until: nil, lock_token: nil)

        if booked_count != expected_locked_count
          ctx[:errors] = { base: ['Booking has expired or seat locks changed before payment confirmation'] }
          raise ActiveRecord::Rollback
        end

        model.update!(status: 'confirmed')

        ctx[:payment] = payment
        confirmation_succeeded = true
      end

      confirmation_succeeded
    rescue ActiveRecord::RecordInvalid => e
      ctx[:errors] = { base: [e.message] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || { base: ['Payment confirmation failed'] }
    end
  end
end
