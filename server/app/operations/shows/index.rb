module Shows
  class Index < ::Trailblazer::Operation
    step :load_shows

    def load_shows(ctx, current_user: nil, params: {}, **)
      ::Show.sync_finished_statuses!

      scope = Pundit.policy_scope!(current_user, ::Show)
                    .includes(:movie, :movie_language, :movie_format,
                              :show_section_prices, screen: :theatre)

      scope = scope.where(screen_id: params[:screen_id]) if params[:screen_id].present?
      status_filter = params[:status].presence || "scheduled"
      scope = scope.where(status: status_filter)
      scope = scope.where(movie_id: params[:movie_id]) if params[:movie_id].present?

      if params[:date].present?
        date = Date.parse(params[:date]) rescue nil
        scope = scope.where(start_time: date.beginning_of_day..date.end_of_day) if date
      end

      if status_filter == "scheduled"
        scope = scope.where("start_time >= ?", Time.current)
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

      records, pagination = Pagination.apply(scope.order(:start_time), params)
      ctx[:records] = records
      ctx[:pagination] = pagination
    end
  end
end
