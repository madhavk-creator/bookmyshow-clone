module Coupons
  class Index < ::Trailblazer::Operation
    step :load_coupons

    def load_coupons(ctx, **)
      ctx[:records] = ::Coupon.active.order(created_at: :desc)
    end
  end
end
