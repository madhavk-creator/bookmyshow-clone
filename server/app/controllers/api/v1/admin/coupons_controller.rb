module Api
  module V1
    module Admin
      class CouponsController < ApplicationController
        before_action :authenticate!

        def index
          authorize!
          
          coupons = ::Coupon.order(created_at: :desc)
          render json: { coupons: coupons.map { |c| serialize(c) } }
        end

        def create
          authorize!

          result = ::Admin::Coupons::Create.call(params: coupon_params.to_h.deep_symbolize_keys)

          if result.success?
            render json: serialize(result[:model]), status: :created
          else
            render json: { errors: result[:errors] }, status: :unprocessable_entity
          end
        end

        def destroy
          authorize!
          
          coupon = ::Coupon.find_by(id: params[:id])
          return render json: { error: 'Not found' }, status: :not_found unless coupon

          if coupon.destroy
            head :no_content
          else
            render json: { errors: coupon.errors.to_hash(true) }, status: :unprocessable_entity
          end
        end

        private

        def authorize!
          return if current_user&.role == 'admin'
          render json: { error: 'Forbidden' }, status: :forbidden
        end

        def coupon_params
          params.require(:coupon).permit(
            :code,
            :coupon_type,
            :valid_from,
            :valid_until,
            :discount_amount,
            :discount_percentage,
            :minimum_booking_amount,
            :max_uses_per_user,
            :max_total_uses
          )
        end

        def serialize(coupon)
          {
            id: coupon.id,
            code: coupon.code,
            coupon_type: coupon.coupon_type,
            valid_from: coupon.valid_from,
            valid_until: coupon.valid_until,
            discount_amount: coupon.discount_amount,
            discount_percentage: coupon.discount_percentage,
            minimum_booking_amount: coupon.minimum_booking_amount,
            max_uses_per_user: coupon.max_uses_per_user,
            max_total_uses: coupon.max_total_uses,
            is_active: coupon.valid_from <= Time.current && coupon.valid_until >= Time.current
          }
        end
      end
    end
  end
end
