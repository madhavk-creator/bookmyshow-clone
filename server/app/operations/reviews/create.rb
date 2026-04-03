module Reviews
  class Create < Trailblazer::Operation
    step :find_movie
    step :check_not_already_reviewed
    step :check_proof_of_purchase
    step :build_review
    step :persist
    fail :collect_errors

    def find_movie(ctx, params:, **)
      ctx[:movie] = Movie.find_by(id: params[:movie_id])
      unless ctx[:movie]
        ctx[:errors] = { movie: ['Movie not found'] }
        return false
      end
    end

    def check_not_already_reviewed(ctx, current_user:, movie:, **)
      if Review.exists?(user_id: current_user.id, movie_id: movie.id)
        ctx[:errors] = { base: ['You have already reviewed this movie'] }
        return false
      end
    end

    # User must have a valid ticket for this movie to leave a review.
    def check_proof_of_purchase(ctx, current_user:, movie:, **)
      watched = Ticket
                  .where(status: 'valid')
                  .joins(show: {})
                  .where(shows: { movie_id: movie.id })
                  .joins(:booking)
                  .where(bookings: { user_id: current_user.id, status: 'confirmed' })
                  .exists?

      unless watched
        ctx[:errors] = { base: ['You can only review movies you have watched'] }
        return false
      end
    end

    def build_review(ctx, params:, current_user:, movie:, **)
      ctx[:model] = ::Review.new(
        user:        current_user,
        movie:       movie,
        description: params[:description],
        rating:      params[:rating],
        reviewed_on: Date.current
      )
    end

    def persist(ctx, model:, **)
      model.save
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end
  end
end