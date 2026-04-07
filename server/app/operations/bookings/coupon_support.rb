module Bookings
  module CouponSupport
    private

    def resolve_coupon_by_code(ctx, coupon_code:)
      coupon = ::Coupon.find_by(code: coupon_code.to_s.upcase.strip)
      return coupon if coupon

      ctx[:errors] = { coupon_code: [ "Coupon not found" ] }
      nil
    end

    def validate_coupon_for_user(ctx:, coupon:, current_user:, subtotal:, exclude_booking_id: nil)
      unless coupon.applicable?(subtotal)
        ctx[:errors] = { coupon_code: [ "Coupon is not applicable to this booking" ] }
        return false
      end

      return true unless coupon.max_uses_per_user.present?

      used_count = ::UserCouponUsage.where(coupon: coupon, user: current_user)
      used_count = used_count.where.not(booking_id: exclude_booking_id) if exclude_booking_id.present?

      return true if used_count.count < coupon.max_uses_per_user

      ctx[:errors] = { coupon_code: [ "You have already used this coupon the maximum number of times" ] }
      false
    end

    def lock_and_validate_coupon!(ctx:, coupon:, current_user:, subtotal:, exclude_booking_id: nil)
      return nil if coupon.nil?

      locked_coupon = ::Coupon.lock.find(coupon.id)
      return locked_coupon if validate_coupon_for_user(
        ctx:,
        coupon: locked_coupon,
        current_user:,
        subtotal:,
        exclude_booking_id:
      )

      nil
    end

    def validate_coupon_global_usage!(ctx:, coupon:, exclude_booking_id: nil)
      return true if coupon.nil?
      return true unless coupon.max_total_uses.present?

      global_uses = ::UserCouponUsage.where(coupon_id: coupon.id)
      global_uses = global_uses.where.not(booking_id: exclude_booking_id) if exclude_booking_id.present?

      return true if global_uses.count < coupon.max_total_uses

      ctx[:errors] = { coupon_code: [ "This coupon has reached its maximum global redemptions" ] }
      false
    end

    def rewrite_coupon_usage!(booking:, coupon:, current_user:)
      ::UserCouponUsage.where(booking_id: booking.id).destroy_all
      return if coupon.nil?

      ::UserCouponUsage.create!(
        coupon: coupon,
        user: current_user,
        booking: booking,
        used_at: Time.current
      )
    end

    def coupon_total(subtotal, coupon)
      coupon ? coupon.apply(subtotal) : subtotal
    end
  end
end
