module Reviews
  class Index < ::Trailblazer::Operation
    step :find_movie
    step :load_reviews

    def find_movie(ctx, params:, **)
      ctx[:movie] = ::Movie.find_by(id: params[:movie_id])
      return true if ctx[:movie]

      ctx[:errors] = { movie: [ "Movie not found" ] }
      false
    end

    def load_reviews(ctx, movie:, params: {}, current_user: nil, **)
      scope = Pundit.policy_scope!(current_user, ::Review)
                    .where(movie_id: movie.id)
                    .includes(:user)
                    .order(reviewed_on: :desc, created_at: :desc)

      records, pagination = Pagination.apply(scope, params)

      ctx[:records] = records
      ctx[:average_rating] = scope.average(:rating)&.round(1)
      ctx[:total_reviews] = scope.count
      ctx[:pagination] = pagination

      true
    end
  end
end
