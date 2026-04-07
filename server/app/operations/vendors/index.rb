module Vendors
  class Index < ::Trailblazer::Operation
    step :load_vendors

    private

    def load_vendors(ctx, **)
      ctx[:records] = User.vendor
                          .active
                          .includes(:theatres)
                          .order(:name)
    end
  end
end
