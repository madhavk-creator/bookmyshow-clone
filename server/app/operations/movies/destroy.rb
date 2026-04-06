module Movies
  class Destroy < ::Trailblazer::Operation
    step :destroy_movie
    fail :collect_errors

    def destroy_movie(ctx, model:, **)
      return true if model.destroy

      ctx[:errors] = model.errors.to_hash(true).presence || { base: [ "Could not delete movie" ] }
      false
    rescue ActiveRecord::DeleteRestrictionError
      ctx[:errors] = { base: [ "Cannot delete a movie that has scheduled shows" ] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || { base: [ "Could not delete movie" ] }
    end
  end
end
