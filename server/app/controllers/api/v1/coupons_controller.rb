module Api
  module V1
    class CouponsController < ApplicationController
      skip_before_action :authenticate!, only: %i[index validate], raise: false
      before_action :authenticate_optional!, only: %i[validate]

      def index
        result = run Coupons::Index do |operation_result|
          return render json: { coupons: CouponSerializer.many(operation_result[:records]) }, status: :ok
        end

        render_operation_errors(result)
      end

      def validate
        result = run Coupons::Validate, params: validate_params do |operation_result|
          return render json: operation_result[:payload], status: :ok
        end

        render_operation_errors(result)
      end

      private

      def validate_params
        params.permit(:code, :booking_amount).to_h.deep_symbolize_keys
      end

      def render_operation_errors(result)
        errors = result[:errors].presence || { base: [ "Coupon request failed" ] }
        render json: { errors: errors }, status: error_status_for(errors)
      end

      def error_status_for(errors)
        messages = errors.values.flatten.map(&:to_s)
        return :not_found if messages.any? { |message| message == "Invalid coupon code" || message.downcase.include?("not found") }
        return :bad_request if errors.key?(:booking_amount)

        :unprocessable_entity
      end
    end
  end
end
