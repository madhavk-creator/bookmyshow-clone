module Movies
  class Index < Trailblazer::Operation
    step :load_movies

    private

    def load_movies(ctx, current_user: nil, params: {}, **)
      scope = Pundit.policy_scope!(current_user, Movie).includes(movie_formats: :formats, movie_languages: :language)
      scope = scope.where('genre ILIKE ?', params[:genre]) if params[:genre].present?
      scope = scope.joins(:languages).where(languages: { code: params[:language].to_s.downcase }) if params[:language].present?
      scope = scope.joins(:formats).where(formats: { code: params[:format].to_s.downcase }) if params[:format].present?

      if params[:city_id].present?
        scope = scope.joins(shows: { screen: :theatre })
                     .where(theatres: { city_id: params[:city_id] })
                     .where(shows: { status: 'scheduled' })
                     .distinct
      end

      ctx[:records] = scope.order(:title)
    end
  end
end
