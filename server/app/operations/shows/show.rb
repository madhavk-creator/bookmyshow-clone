module Shows
  class Show < ::Trailblazer::Operation
    step :find_show
    step :authorize_show
    fail :collect_errors

    def find_show(ctx, params:, **)
      scope = ::Show.includes(
        :movie,
        :movie_language,
        :movie_format,
        :seat_layout,
        show_section_prices: :seat_section,
        screen: [ :theatre ]
      )

      scope = scope.where(screen_id: params[:screen_id]) if params[:screen_id].present?
      scope = scope.joins(screen: :theatre).where(theatres: { id: params[:theatre_id] }) if params[:theatre_id].present?

      ctx[:model] = scope.find_by(id: params[:id])
      return true if ctx[:model]

      ctx[:errors] = { base: [ "Show not found" ] }
      false
    end

    def authorize_show(ctx, model:, current_user: nil, **)
      return true if Pundit.policy!(current_user, model).show?

      ctx[:errors] = { base: [ "Not authorized to view this show" ] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end
  end
end
