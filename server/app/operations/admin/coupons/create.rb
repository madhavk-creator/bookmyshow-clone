module Admin
  module Coupons
    class Create < Trailblazer::Operation
      step :validate_params
      step :create_coupon

      def validate_params(ctx, params:, **)
        ctx[:errors] = {}

        [:code, :coupon_type, :valid_from, :valid_until].each do |field|
          if params[field].blank?
            ctx[:errors][field] = ["can't be blank"]
          end
        end

        if params[:coupon_type] == 'amount' && params[:discount_amount].blank?
          ctx[:errors][:discount_amount] = ["must be present for amount coupons"]
        end

        if params[:coupon_type] == 'percentage' && params[:discount_percentage].blank?
          ctx[:errors][:discount_percentage] = ["must be present for percentage coupons"]
        end

        return false if ctx[:errors].any?
        true
      end

      def create_coupon(ctx, params:, **)
        coupon = ::Coupon.new(
          code: params[:code],
          coupon_type: params[:coupon_type],
          valid_from: params[:valid_from],
          valid_until: params[:valid_until],
          discount_amount: params[:discount_amount],
          discount_percentage: params[:discount_percentage],
          minimum_booking_amount: params[:minimum_booking_amount],
          max_uses_per_user: params[:max_uses_per_user],
          max_total_uses: params[:max_total_uses]
        )

        if coupon.save
          ctx[:model] = coupon
          true
        else
          ctx[:errors] = coupon.errors.to_hash(true)
          false
        end
      end
    end
  end
end
