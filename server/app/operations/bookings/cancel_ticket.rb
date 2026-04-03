module Bookings
  # Cancels a single ticket within a confirmed booking.
  # Updates booking.total_amount to reflect the deduction.
  # Creates a completed PaymentRefund for that ticket's price in the simulated gateway flow.
  # If all tickets end up cancelled, the booking itself is cancelled too.

  class CancelTicket < Trailblazer::Operation
    step :find_booking
    step :find_ticket
    step :validate_cancellable
    step :cancel_ticket_transactionally
    fail :collect_errors

    def find_booking(ctx, params:, **)
      ctx[:model] = ::Booking.includes(:payments, :tickets).find_by(id: params[:booking_id])
      unless ctx[:model]
        ctx[:errors] = { base: ['Booking not found'] }
        return false
      end

      true
    end

    def find_ticket(ctx, params:, model:, **)
      ctx[:ticket] = model.tickets.find_by(id: params[:ticket_id])
      unless ctx[:ticket]
        ctx[:errors] = { base: ['Ticket not found in this booking'] }
        return false
      end

      true
    end

    def validate_cancellable(ctx, model:, ticket:, **)
      unless model.status_confirmed?
        ctx[:errors] = { base: ["Booking is #{model.status} — cannot cancel ticket"] }
        return false
      end

      unless ticket.status_valid?
        ctx[:errors] = { base: ['Ticket is already cancelled'] }
        return false
      end

      true
    end

    def cancel_ticket_transactionally(ctx, model:, ticket:, **)
      payment = model.payments.find_by(status: 'completed')
      refund = nil

      ActiveRecord::Base.transaction do
        ShowSeatState.where(
          show_id: model.show_id,
          seat_id: ticket.seat_id,
          status:  'booked'
        ).delete_all

        ticket.update!(status: 'cancelled')

        if payment
          refund = PaymentRefund.create!(
            payment: payment,
            ticket:  ticket,
            amount:  ticket.price,
            status:  'completed'
          )
        end

        model.update!(total_amount: model.total_amount - ticket.price)

        unless model.tickets.where(status: 'valid').exists?
          model.update!(status: 'cancelled')
          payment&.update!(status: 'refunded')
        end
      end

      ctx[:refund] = refund if refund
      true
    rescue ActiveRecord::RecordInvalid => e
      ctx[:errors] = { base: [e.message] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= { base: ['Ticket could not be cancelled'] }
    end
  end
end
