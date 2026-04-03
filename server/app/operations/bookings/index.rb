module Bookings
  class Index < Trailblazer::Operation
    step :load_bookings

    private

    def load_bookings(ctx, current_user:, params: {}, **)
      scope = Pundit.policy_scope!(current_user, Booking)
                    .includes(:show, :tickets, :coupon)
                    .order(booking_time: :desc)

      records, pagination = Pagination.apply(scope, params)
      ctx[:records] = records
      ctx[:pagination] = pagination
    end
  end
end
