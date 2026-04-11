module Bookings
  class Index < ::Trailblazer::Operation
    step :load_bookings
    step :refresh_pending_expirations

    private

    def load_bookings(ctx, current_user:, params: {}, **)
      scope = Pundit.policy_scope!(current_user, Booking)
                    .includes(:show, :tickets, :coupon)
                    .order(booking_time: :desc)

      records, pagination = Pagination.apply(scope, params)
      ctx[:records] = records
      ctx[:pagination] = pagination
    end

    def refresh_pending_expirations(ctx, records:, **)
      ctx[:records] = records.filter_map(&:refresh_expiration!)
    end
  end
end
