module Cities
  class Destroy < ::Trailblazer::Operation
    step :destroy
    fail :collect_errors

    def destroy(ctx, model:, **)
      model.destroy
    rescue ActiveRecord::DeleteRestrictionError
      ctx[:errors] = { base: [ "Cannot delete a city that has theatres" ] }
      false
    end

    def collect_errors(ctx, model:, **)
      ctx[:errors] ||= model.errors.to_hash(true).presence || { base: [ "Could not delete city" ] }
    end
  end
end
