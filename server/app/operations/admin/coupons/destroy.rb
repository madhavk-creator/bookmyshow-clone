module Admin
  module Coupons
    class Destroy < ::Trailblazer::Operation
      step :find_coupon
      step :destroy_coupon
      fail :collect_errors

      def find_coupon(ctx, params:, **)
        ctx[:model] = ::Coupon.find_by(id: params[:id])
        return true if ctx[:model]

        ctx[:not_found] = true
        ctx[:errors] = { base: [ "Coupon not found" ] }
        false
      end

      def destroy_coupon(ctx, model:, **)
        model.destroy
      end

      def collect_errors(ctx, model: nil, **)
        ctx[:errors] ||= model&.errors&.to_hash(true) || { base: [ "Could not delete coupon" ] }
      end
    end
  end
end
