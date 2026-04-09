module Api
  module V1
    module Admin
      class CouponsController < ApplicationController
        before_action :authenticate!
        before_action :authorize_admin!

        def index
          render json: { coupons: CouponSerializer
          .many(::Coupon.order(created_at: :desc), admin: true) }
        end

        def create
          result = run(::Admin::Coupons::Create, params: coupon_params
          .to_h.deep_symbolize_keys) do |result|
            return render json: CouponSerializer.one(result[:model], admin: true),
              status: :created
          end

          render_errors(result)
        end

        def destroy
          result = run(::Admin::Coupons::Destroy, params: { id: params[:id] }) do
            head :no_content
          end

          return if result.success?

          if result[:not_found]
            render json: { error: "Not found" }, status: :not_found
          else
            render_errors(result)
          end
        end

        private

        def authorize_admin!
          return if current_user&.role == "admin"

          render json: { error: "Forbidden" }, status: :forbidden
        end

        def coupon_params = params.require(:coupon).permit(
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

        def render_errors(result) = render(json: { errors: result[:errors] },
          status: :unprocessable_entity)
      end
    end
  end
end
