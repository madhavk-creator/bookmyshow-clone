module Languages
  class Destroy < Trailblazer::Operation
    step :destroy
    fail :collect_errors

    private

    def destroy(ctx, model:, **)
      model.destroy
    rescue ActiveRecord::DeleteRestrictionError
      ctx[:errors] = { base: ['Cannot delete a languages that is in use by movies'] }
      false
    end

    def collect_errors(ctx, **)
      ctx[:errors] ||= { base: ['Could not delete languages'] }
    end
  end
end
