module Coupons
  class Validate < ::Trailblazer::Operation
    step :find_coupon
    step :resolve_subtotal
    step :validate_applicable
    step :validate_user_limit
    step :build_payload
    fail :collect_errors

    def find_coupon(ctx, params:, **)
      code = params[:code].to_s.upcase.strip
      ctx[:coupon] = ::Coupon.find_by(code: code)
      return true if ctx[:coupon]

      ctx[:errors] = { base: [ "Invalid coupon code" ] }
      false
    end

    def resolve_subtotal(ctx, params:, **)
      booking_amount = params[:booking_amount]
      if booking_amount.blank?
        ctx[:errors] = { booking_amount: [ "is required" ] }
        return false
      end

      ctx[:subtotal] = BigDecimal(booking_amount.to_s)
      true
    rescue ArgumentError
      ctx[:errors] = { booking_amount: [ "must be a valid number" ] }
      false
    end

    def validate_applicable(ctx, coupon:, subtotal:, **)
      return true if coupon.applicable?(subtotal)

      ctx[:errors] = { base: [ "Coupon is not applicable to this booking amount or has expired" ] }
      false
    end

    def validate_user_limit(ctx, coupon:, current_user: nil, **)
      return true if coupon.max_uses_per_user.blank?

      unless current_user
        ctx[:errors] = { base: [ "This coupon can only be used by registered users" ] }
        return false
      end

      used_count = ::UserCouponUsage.where(coupon: coupon, user: current_user).count
      return true if used_count < coupon.max_uses_per_user

      ctx[:errors] = { base: [ "You have already used this coupon the maximum number of times" ] }
      false
    end

    def build_payload(ctx, coupon:, subtotal:, **)
      discount = subtotal - coupon.apply(subtotal)

      ctx[:payload] = {
        valid: true,
        code: coupon.code,
        original_amount: subtotal,
        discount_amount: discount,
        final_amount: subtotal - discount,
        coupon_type: coupon.coupon_type
      }
    end

    def collect_errors(ctx, coupon: nil, **)
      ctx[:errors] ||= coupon&.errors&.to_hash(true) || { base: [ "Coupon validation failed" ] }
    end
  end
end
