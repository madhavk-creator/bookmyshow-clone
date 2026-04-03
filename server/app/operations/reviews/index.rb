module Reviews
  class Index < Trailblazer::Operation
    step :load_reviews

    private

    def load_reviews(ctx, current_user: nil, params: {}, **)
      reviews = Pundit.policy_scope!(current_user, Review)
                      .where(movie_id: params[:movie_id])
                      .includes(:user)
                      .order(reviewed_on: :desc)

      records, pagination = Pagination.apply(reviews, params)
      ctx[:records] = records
      ctx[:average_rating] = reviews.average(:rating)&.round(1)
      ctx[:total_reviews] = reviews.count
      ctx[:pagination] = pagination
    end
  end
end
