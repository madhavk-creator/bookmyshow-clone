module Bookings
  # Cancels all valid tickets and releases their booked seat states.
  # Creates a completed PaymentRefund per ticket in the simulated gateway flow.
  # Policy enforces: before show starts only.

  class Cancel < ::Trailblazer::Operation
    include CouponSupport

    step :find_booking
    step :authorize_booking
    step :validate_cancellable
    step :cancel_transactionally
    fail :collect_errors

    def find_booking(ctx, params:, current_user:, **)
      ctx[:model] = Pundit.policy_scope!(current_user, ::Booking).includes(:coupon, :payments, tickets: {}).find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { booking: [ "Not found" ] }
        return false
      end

      true
    end

    def authorize_booking(ctx, model:, current_user:, **)
      return true if Pundit.policy!(current_user, model).cancel?

      ctx[:errors] = { base: [ "Not authorized to cancel this booking" ] }
      false
    end

    def validate_cancellable(ctx, model:, **)
      unless model.status_confirmed?
        ctx[:errors] = { base: [ "Only confirmed bookings can be cancelled (current: #{model.status})" ] }
        return false
      end

      true
    end

    def cancel_transactionally(ctx, model:, **)
      valid_tickets = model.tickets.where(status: "valid").to_a
      seat_ids = valid_tickets.map(&:seat_id)
      payment = model.payments.find_by(status: "completed")

      ActiveRecord::Base.transaction do
        # Delete the booked seat state rows — seats become available again
        ShowSeatState.where(show_id: model.show_id, seat_id: seat_ids, status: "booked")
                     .delete_all

        model.tickets.where(id: valid_tickets.map(&:id)).update_all(status: "cancelled")

        valid_tickets.each do |ticket|
          next unless payment

          PaymentRefund.create!(
            payment: payment,
            ticket:  ticket,
            amount:  ticket.price,
            status:  "completed"
          )
        end

        model.update!(total_amount: coupon_total(model.reload.valid_tickets_subtotal, model.coupon), status: "cancelled")
        payment&.update!(status: "refunded")
      end

      ctx[:model] = model.reload
      ctx[:valid_tickets] = valid_tickets
      true
    rescue ActiveRecord::RecordInvalid => e
      ctx[:errors] = { base: [ e.message ] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= { base: [ "Booking could not be cancelled" ] }
    end
  end
end
