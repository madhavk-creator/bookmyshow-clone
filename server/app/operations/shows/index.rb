module Shows
  class Index < Trailblazer::Operation
    step :load_shows

    private

    def load_shows(ctx, current_user: nil, params: {}, **)
      scope = Pundit.policy_scope!(current_user, Show)
                    .includes(:movie, :movie_language, :movie_format,
                              :show_section_prices, screen: :theatre)

      scope = scope.where(screen_id: params[:screen_id]) if params[:screen_id].present?
      scope = params[:status].present? ? scope.where(status: params[:status]) : scope.where(status: 'scheduled')
      scope = scope.where(movie_id: params[:movie_id]) if params[:movie_id].present?

      if params[:date].present?
        date = Date.parse(params[:date]) rescue nil
        scope = scope.where(start_time: date.beginning_of_day..date.end_of_day) if date
      end

      if params[:language].present?
        scope = scope.joins(movie_language: :language)
                     .where(languages: { code: params[:language].to_s.downcase })
      end

      if params[:format].present?
        scope = scope.joins(movie_format: :format)
                     .where(formats: { code: params[:format].to_s.downcase })
      end

      if params[:city_id].present?
        scope = scope.joins(screen: :theatre)
                     .where(theatres: { city_id: params[:city_id] })
      end

      ctx[:records] = scope.order(:start_time)
    end
  end
end
