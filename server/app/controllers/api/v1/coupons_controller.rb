module Api
  module V1
    class CouponsController < ApplicationController
      skip_before_action :authenticate!, only: [:index, :validate], raise: false

      def index
        # Return all active coupons 
        coupons = ::Coupon.active.order(created_at: :desc)
        render json: { 
          coupons: coupons.map do |c|
            {
              id: c.id,
              code: c.code,
              coupon_type: c.coupon_type,
              discount_amount: c.discount_amount,
              discount_percentage: c.discount_percentage,
              valid_until: c.valid_until,
              minimum_booking_amount: c.minimum_booking_amount,
              max_uses_per_user: c.max_uses_per_user
            }
          end
        }
      end

      def validate
        coupon = ::Coupon.find_by(code: params[:code].to_s.upcase.strip)
        
        unless coupon
          return render json: { error: 'Invalid coupon code' }, status: :not_found
        end

        subtotal = params[:booking_amount].to_d

        if !coupon.applicable?(subtotal)
          return render json: { error: 'Coupon is not applicable to this booking amount or has expired' }, status: :unprocessable_entity
        end

        # Check per-user limit if max_uses_per_user is set, and the user is logged in
        if coupon.max_uses_per_user.present?
          if current_user
            used_count = ::UserCouponUsage.where(coupon: coupon, user: current_user).count
            if used_count >= coupon.max_uses_per_user
              return render json: { error: 'You have already used this coupon the maximum number of times' }, status: :unprocessable_entity
            end
          else
            # If the user is a guest but the coupon requires user limit checking, we might just reject it for guests our backend is doing this
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
