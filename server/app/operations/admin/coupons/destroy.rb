module Admin
  module Coupons
    class Destroy < ::Trailblazer::Operation
      step :find_coupon
      step :archive_coupon
      fail :collect_errors

      def find_coupon(ctx, params:, **)
        ctx[:model] = ::Coupon.find_by(id: params[:id])
        return true if ctx[:model]

        ctx[:not_found] = true
        ctx[:errors] = { base: [ "Coupon not found" ] }
        false
      end

      def archive_coupon(ctx, model:, **)
        cutoff = Time.current
        archived_time = cutoff - 1.second
        attributes = {
          valid_until: archived_time,
          updated_at: cutoff
        }
        attributes[:valid_from] = archived_time if model.valid_from.present? && model.valid_from > archived_time

        model.update_columns(attributes)
        ctx[:model] = model.reload
        true
      end

      def collect_errors(ctx, model: nil, **)
        ctx[:errors] ||= model&.errors&.to_hash(true) || { base: [ "Could not archive coupon" ] }
      end
    end
  end
end
