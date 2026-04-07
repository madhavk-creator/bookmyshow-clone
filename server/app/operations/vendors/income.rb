module Vendors
  class Income < ::Trailblazer::Operation
    step :calculate_income

    private

    def calculate_income(ctx, vendor:, **)
      theatre_ids = vendor.theatres.select(:id)

      payments_scope = Payment.joins(booking: { show: { screen: :theatre } })
                              .where(theatres: { id: theatre_ids })
                              .where(status: %w[completed refunded])

      refunds_scope = PaymentRefund.joins(ticket: { show: { screen: :theatre } })
                                   .where(theatres: { id: theatre_ids }, status: "completed")

      booking_scope = Booking.joins(show: { screen: :theatre })
                             .where(theatres: { id: theatre_ids }, status: "confirmed")

      ticket_scope = Ticket.joins(show: { screen: :theatre })
                           .where(theatres: { id: theatre_ids }, status: "valid")

      ctx[:theatres_count] = vendor.theatres.count
      ctx[:completed_bookings_count] = booking_scope.distinct.count
      ctx[:tickets_sold_count] = ticket_scope.count
      ctx[:gross_income] = payments_scope.sum(:amount)
      ctx[:refund_amount] = refunds_scope.sum(:amount)
      ctx[:total_income] = ctx[:gross_income] - ctx[:refund_amount]
    end
  end
end
