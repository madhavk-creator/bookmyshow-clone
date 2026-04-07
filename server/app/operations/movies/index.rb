module Movies
  class Index < ::Trailblazer::Operation
    step :load_movies

    private

    def load_movies(ctx, current_user: nil, params: {}, **)
      scope = Pundit.policy_scope!(current_user, Movie).includes(movie_formats: :format, movie_languages: :language)
      requires_distinct = false

      scope = scope.where("genre ILIKE ?", params[:genre]) if params[:genre].present?
      if params[:language].present?
        scope = scope.joins(:languages).where(languages: { code: params[:language].to_s.downcase })
        requires_distinct = true
      end
      if params[:format].present?
        scope = scope.joins(:formats).where(formats: { code: params[:format].to_s.downcase })
        requires_distinct = true
      end

      if params[:city_id].present?
        scope = scope.joins(shows: { screen: :theatre })
                     .where(theatres: { city_id: params[:city_id] })
                     .where(shows: { status: "scheduled" })
        requires_distinct = true
      end

      scope = scope.distinct if requires_distinct

      records, pagination = Pagination.apply(scope.order(:title), params)
      ctx[:records] = records
      ctx[:pagination] = pagination
    end
  end
end
