module Movies
  class Destroy < Trailblazer::Operation
    step :destroy
    fail :collect_errors

    def destroy(ctx, model:, **)
      model.destroy
    rescue ActiveRecord::DeleteRestrictionError
      ctx[:errors] = { base: ['Cannot delete a movies that has scheduled shows'] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= { base: ['Could not delete movies'] }
    end
  end
end