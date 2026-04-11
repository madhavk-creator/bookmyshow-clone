module Movies
  class Destroy < ::Trailblazer::Operation
    step :find_movie
    step :authorize_movie
    step :ensure_no_active_shows
    step :destroy_movie
    fail :collect_errors

    def find_movie(ctx, params:, model: nil, **)
      return true if model.present?

      ctx[:model] = ::Movie.find_by(id: params[:id])
      return true if ctx[:model]

      ctx[:errors] = { base: [ "Movie not found" ] }
      false
    end

    def authorize_movie(ctx, model:, current_user:, **)
      return true if Pundit.policy!(current_user, model).destroy?

      ctx[:errors] = { base: [ "Not authorized to delete this movie" ] }
      false
    end

    def ensure_no_active_shows(ctx, model:, **)
      return true unless model.shows.where(status: "scheduled").where("end_time > ?", Time.current).exists?

      ctx[:errors] = { base: [ "Cannot delete a movie while it has running or upcoming shows" ] }
      false
    end

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
