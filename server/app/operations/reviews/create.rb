module Reviews
  class Create < ::Trailblazer::Operation
    step :find_movie
    step :check_not_already_reviewed
    step :check_proof_of_purchase
    step :build_review
    step :persist_review
    fail :collect_errors

    include OperationHelpers

    def find_movie(ctx, params:, **)
      ctx[:movie] = ::Movie.find_by(id: params[:movie_id])
      return true if ctx[:movie]

      ctx[:errors] = { movie: [ "Movie not found" ] }
      false
    end

    def check_not_already_reviewed(ctx, current_user:, movie:, **)
      if ::Review.exists?(user_id: current_user.id, movie_id: movie.id)
        ctx[:errors] = { base: [ "You have already reviewed this movie" ] }
        return false
      end

      true
    end

    def check_proof_of_purchase(ctx, current_user:, movie:, **)
      watched = ::Ticket
                  .joins(:booking, :show)
                  .where(status: "valid")
                  .where(bookings: { user_id: current_user.id, status: "confirmed" })
                  .where(shows: { movie_id: movie.id })
                  .where("shows.start_time < ?", Time.current)
                  .exists?

      return true if watched

      ctx[:errors] = { base: [ "You can only review movies you have watched" ] }
      false
    end

    def build_review(ctx, params:, current_user:, movie:, **)
      ctx[:model] = ::Review.new(
        user: current_user,
        movie: movie,
        rating: params[:rating],
        description: params[:description],
        reviewed_on: Date.current
      )

      true
    end

    def persist_review(ctx, model:, **)
      model.save
    end

    def collect_errors(ctx, model: nil, **)
      collect_default_errors(ctx, model: model, fallback: "Could not create review")
    end
  end
end
