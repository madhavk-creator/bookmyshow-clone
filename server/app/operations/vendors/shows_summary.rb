module Vendors
  class ShowsSummary < ::Trailblazer::Operation
    step :find_vendor
    step :authorize_vendor
    step :load_summary

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

    def load_summary(ctx, vendor:, **)
      ::Show.sync_finished_statuses!

      theatre_ids = vendor.theatres.select(:id)

      shows = ::Show
                .joins(screen: :theatre)
                .where(theatres: { id: theatre_ids }, status: %w[scheduled completed])
                .includes(:movie, screen: :theatre)
                .order(start_time: :desc)

      gross_income_by_show = ::Payment
                               .joins(booking: :show)
                               .where(shows: { id: shows.select(:id) })
                               .where(status: %w[completed refunded])
                               .group("shows.id")
                               .sum(:amount)

      refund_amount_by_show = ::PaymentRefund
                                .joins(ticket: :show)
                                .where(shows: { id: shows.select(:id) }, status: "completed")
                                .group("shows.id")
                                .sum(:amount)

      valid_tickets_by_show = ::Ticket
                                .where(show_id: shows.select(:id), status: "valid")
                                .group(:show_id)
                                .count

      confirmed_bookings_by_show = ::Booking
                                     .where(show_id: shows.select(:id), status: "confirmed")
                                     .group(:show_id)
                                     .count

      ctx[:records] = shows.map do |show|
        gross_income = gross_income_by_show[show.id].to_f
        refund_amount = refund_amount_by_show[show.id].to_f
        seats_booked = valid_tickets_by_show[show.id].to_i

        {
          id: show.id,
          status: show.status,
          start_time: show.start_time,
          end_time: show.end_time,
          total_capacity: show.total_capacity,
          seats_booked: seats_booked,
          occupancy_rate: show.total_capacity.to_i.positive? ? ((seats_booked.to_f / show.total_capacity) * 100).round(1) : 0.0,
          confirmed_bookings_count: confirmed_bookings_by_show[show.id].to_i,
          gross_income: gross_income,
          refund_amount: refund_amount,
          total_income: gross_income - refund_amount,
          movie: {
            id: show.movie.id,
            title: show.movie.title
          },
          screen: {
            id: show.screen.id,
            name: show.screen.name
          },
          theatre: {
            id: show.screen.theatre.id,
            name: show.screen.theatre.name
          }
        }
      end
    end
  end
end
