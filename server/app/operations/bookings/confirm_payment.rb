module Bookings
  class ConfirmPayment < ::Trailblazer::Operation
    step :find_booking
    step :authorize_booking
    step :validate_booking_state
    step :find_pending_payment
    step :confirm_payment_transactionally
    fail :collect_errors

    def find_booking(ctx, params:, current_user:, **)
      ctx[:model] = ::Booking
        .includes(:payments, :tickets, show: {})
        .find_by(id: params[:id], user_id: current_user.id)

      return true if ctx[:model].present?

      ctx[:errors] = { booking: [ "Not found" ] }
      false
    end

    def authorize_booking(ctx, model:, current_user:, **)
      unless Pundit.policy!(current_user, model).confirm_payment?
        ctx[:errors] = { base: [ "Not authorized to confirm this booking" ] }
        return false
      end

      true
    end

    def validate_booking_state(ctx, model:, **)
      unless model.status_pending?
        ctx[:errors] = { booking: [ "Booking is #{model.status} and cannot be confirmed" ] }
        return false
      end

      locked_scope = locked_seat_states_for(model)

      if locked_scope.count != model.tickets.size
        ctx[:errors] = { booking: [ "Booking has expired or seat locks are no longer valid" ] }
        return false
      end

      true
    end

    def find_pending_payment(ctx, model:, **)
      ctx[:payment] = model.payments.find_by(status: "pending")

      return true if ctx[:payment].present?

      ctx[:errors] = { payment: [ "No pending payment found for this booking" ] }
      false
    end

    def confirm_payment_transactionally(ctx, model:, payment:, **)
      success = false

      ActiveRecord::Base.transaction do
        create_transaction_record!(payment)

        payment.update!(
          status:  "completed",
          paid_at: Time.current
        )

        booked_count = lock_and_book_seats!(model)

        if booked_count != model.tickets.size
          ctx[:errors] = { booking: [ "Booking has expired or seat locks changed before confirmation" ] }
          raise ActiveRecord::Rollback
        end

        model.update!(status: "confirmed")

        ctx[:model]   = model
        ctx[:payment] = payment
        success = true
      end

      success
    rescue ActiveRecord::RecordInvalid => e
      ctx[:errors] = extract_errors(e, model)
      false
    rescue ActiveRecord::ActiveRecordError => e
      ctx[:errors] = { base: [  e.message ] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || { base: [ "Payment confirmation failed" ] }
    end

    private

    def locked_seat_states_for(booking)
      ::ShowSeatState
        .where(lock_token: booking.lock_token, status: "locked")
        .where("locked_until >= ?", Time.current)
    end

    def create_transaction_record!(payment)
      ::Transaction.create!(
        payment:          payment,
        ref_no:           generated_ref_no,
        payment_method:   "simulated",
        amount:           payment.amount,
        transaction_time: Time.current,
        status:           "completed"
      )
    end

    def lock_and_book_seats!(booking)
      locked_seat_states_for(booking).update_all(
        status:       "booked",
        locked_until: nil,
        lock_token:   nil
      )
    end

    def generated_ref_no
      "SIM-#{SecureRandom.hex(8).upcase}"
    end

    def extract_errors(error, model)
      record = error.respond_to?(:record) ? error.record : nil
      return record.errors.to_hash(true) if record&.errors&.any?

      model.errors.to_hash(true).presence || { base: [ error.message ] }
    end
  end
end
