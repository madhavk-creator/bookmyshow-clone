module Bookings
  class Show < ::Trailblazer::Operation
    step :find_booking
    step :authorize_booking
    step :refresh_pending_expiration
    fail :collect_errors

    def find_booking(ctx, params:, current_user:, **)
      ctx[:model] = Pundit.policy_scope!(current_user, ::Booking)
                          .includes(:show, :tickets, :coupon, :payments)
                          .find_by(id: params[:id])
      return true if ctx[:model].present?

      ctx[:errors] = { booking: [ "Not found" ] }
      false
    end

    def authorize_booking(ctx, model:, current_user:, **)
      return true if Pundit.policy!(current_user, model).show?

      ctx[:errors] = { base: [ "Not authorized to view this booking" ] }
      false
    end

    def refresh_pending_expiration(ctx, model:, **)
      ctx[:model] = model.refresh_expiration!
      if ctx[:model].present?
        return true
      end

      ctx[:errors] = { booking: [ "Not found" ] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end
  end
end
