module Languages
  class Destroy < ::Trailblazer::Operation
    step :destroy
    fail :collect_errors

    def destroy(ctx, model:, **)
      model.destroy
    rescue ActiveRecord::DeleteRestrictionError
      ctx[:errors] = { base: [ "Cannot delete a language that is in use by movies" ] }
      false
    end

    def collect_errors(ctx, **)
      ctx[:errors] ||= { base: [ "Could not delete language" ] }
    end
  end
end
