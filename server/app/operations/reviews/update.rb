module Reviews
  class Update < ::Trailblazer::Operation
    step :find_movie
    step :find_review
    step :assign_attributes
    step :persist_review
    fail :collect_errors

    include OperationHelpers

    def find_movie(ctx, params:, **)
      ctx[:movie] = ::Movie.find_by(id: params[:movie_id])
      return true if ctx[:movie]

      ctx[:errors] = { movie: [ "Movie not found" ] }
      false
    end

    def find_review(ctx, params:, current_user:, movie:, **)
      ctx[:model] = ::Review.includes(:user)
                            .find_by(
                              id: params[:id],
                              movie_id: movie.id,
                              user_id: current_user.id
                            )

      return true if ctx[:model]

      ctx[:errors] = { review: [ "Review not found" ] }
      false
    end

    def assign_attributes(ctx, params:, model:, **)
      model.rating = params[:rating] if params.key?(:rating)
      model.description = params[:description] if params.key?(:description)
      true
    end

    def persist_review(ctx, model:, **)
      model.save
    end

    def collect_errors(ctx, model: nil, **)
      collect_default_errors(ctx, model: model, fallback: "Could not update review")
    end
  end
end
