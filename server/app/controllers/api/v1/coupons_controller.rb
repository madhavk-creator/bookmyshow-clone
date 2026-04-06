module Api
  module V1
    class CouponsController < ApplicationController
      skip_before_action :authenticate!, only: [ :index, :validate_coupon ], raise: false

      def index
        # Return all active coupons
        coupons = ::Coupon.active.order(created_at: :desc)
        render json: { coupons: CouponSerializer.many(coupons) }
      end

      def validate_coupon
        coupon = ::Coupon.find_by(code: params[:code].to_s.upcase.strip)

        unless coupon
          return render json: { error: "Invalid coupon code" }, status: :not_found
        end

        booking_amount = params[:booking_amount]
        return render json: { errors: [ "booking_amount is required" ] }, status: :bad_request if booking_amount.blank?

        subtotal = BigDecimal(booking_amount.to_s)

        if !coupon.applicable?(subtotal)
          return render json: { error: "Coupon is not applicable to this booking amount or has expired" }, status: :unprocessable_entity
        end

        # Check per-user limit if max_uses_per_user is set, and the user is logged in
        if coupon.max_uses_per_user.present?
          if current_user
            used_count = ::UserCouponUsage.where(coupon: coupon, user: current_user).count
            if used_count >= coupon.max_uses_per_user
              return render json: { error: "You have already used this coupon the maximum number of times" }, status: :unprocessable_entity
            end
          else
            return render json: { error: "This coupon can only be used by registered users" }, status: :unprocessable_entity
          end

        end

        discount = subtotal - coupon.apply(subtotal)

        render json: {
          valid: true,
          code: coupon.code,
          original_amount: subtotal,
          discount_amount: discount,
          final_amount: subtotal - discount,
          coupon_type: coupon.coupon_type
        }
      end
    end
  end
end
