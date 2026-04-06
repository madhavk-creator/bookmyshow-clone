module Reviews
  class Show < ::Trailblazer::Operation
    step :find_movie
    step :find_review
    fail :collect_errors

    include OperationHelpers

    def find_movie(ctx, params:, **)
      ctx[:movie] = ::Movie.find_by(id: params[:movie_id])
      return true if ctx[:movie]

      ctx[:errors] = { movie: [ "Movie not found" ] }
      false
    end

    def find_review(ctx, movie:, params:, current_user: nil, **)
      ctx[:model] = Pundit.policy_scope!(current_user, ::Review)
                          .includes(:user)
                          .find_by(id: params[:id], movie_id: movie.id)

      return true if ctx[:model]

      ctx[:errors] = { review: [ "Review not found" ] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      collect_default_errors(ctx, model: model, fallback: "Could not load review")
    end
  end
end
