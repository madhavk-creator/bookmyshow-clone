module Reviews
  class Destroy < Trailblazer::Operation
    step :find_review
    step :destroy
    fail :collect_errors

    def find_review(ctx, params:, **)
      ctx[:model] = ::Review.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: ['Review not found'] }
        return false
      end
    end

    def destroy(ctx, model:, **)
      model.destroy
    end

    def collect_errors(ctx, **)
      ctx[:errors] ||= { base: ['Could not delete review'] }
    end
  end
end