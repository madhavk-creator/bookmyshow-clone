module Movies
  class Show < ::Trailblazer::Operation
    step :find_movie
    step :authorize_movie
    fail :collect_errors

    def find_movie(ctx, params:, **)
      ctx[:model] = ::Movie.includes(:movie_languages, :movie_formats, :languages, :formats, :cast_members)
                           .find_by(id: params[:id])
      return true if ctx[:model]

      ctx[:errors] = { base: [ "Movie not found" ] }
      false
    end

    def authorize_movie(ctx, model:, current_user: nil, **)
      return true if Pundit.policy!(current_user, model).show?

      ctx[:errors] = { base: [ "Not authorized to view this movie" ] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end
  end
end
