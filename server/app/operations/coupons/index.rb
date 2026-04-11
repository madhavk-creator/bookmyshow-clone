module Coupons
  class Index < ::Trailblazer::Operation
    step :resolve_booking_context
    step :load_coupons

    def resolve_booking_context(ctx, params: {}, current_user: nil, **)
      ctx[:booking] = nil
      return true if params[:booking_id].blank?

      unless current_user
        ctx[:errors] = { base: [ "Authentication required to load booking-specific coupons" ] }
        return false
      end

      booking = ::Booking
        .includes(:coupon)
        .find_by(id: params[:booking_id], user_id: current_user.id)

      unless booking&.status_pending?
        ctx[:errors] = { booking: [ "Pending booking not found" ] }
        return false
      end

      ctx[:booking] = booking.refresh_expiration!

      unless ctx[:booking]&.status_pending?
        ctx[:errors] = { booking: [ "Booking is no longer pending" ] }
        return false
      end

      true
    end

    def load_coupons(ctx, booking: nil, current_user: nil, **)
      scope = ::Coupon.active.order(created_at: :desc)
      return ctx[:records] = scope unless booking && current_user

      subtotal = booking.valid_tickets_subtotal
      records = scope.select do |coupon|
        coupon.applicable?(subtotal) &&
          eligible_for_user?(coupon, current_user)
      end

      ctx[:records] = records
    end

    private

    def eligible_for_user?(coupon, current_user)
      return true if coupon.max_uses_per_user.blank?

      ::UserCouponUsage.where(coupon: coupon, user: current_user).count < coupon.max_uses_per_user
    end
  end
end
