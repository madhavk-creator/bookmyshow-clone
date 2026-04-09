module Vendors
  class Income < ::Trailblazer::Operation
    step :find_vendor
    step :authorize_vendor
    step :calculate_income

    private

    def find_vendor(ctx, params:, **)
      ctx[:vendor] = ::User.find_by(id: params[:id], role: :vendor)
      return true if ctx[:vendor]

      ctx[:errors] = { vendor: [ "Vendor not found" ] }
      false
    end

    def authorize_vendor(ctx, current_user:, vendor:, **)
      return true if Pundit.policy!(current_user, vendor).income?

      ctx[:errors] = { base: [ "Forbidden" ] }
      false
    end

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
      ctx[:gross_income] = payments_scope.sum(:amount).to_f
      ctx[:refund_amount] = refunds_scope.sum(:amount).to_f
      ctx[:total_income] = ctx[:gross_income] - ctx[:refund_amount]
    end
  end
end
