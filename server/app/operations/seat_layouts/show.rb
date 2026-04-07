module SeatLayouts
  class Show < ::Trailblazer::Operation
    step :find_screen
    step :find_layout
    step :authorize_layout
    fail :collect_errors

    def find_screen(ctx, params:, **)
      ctx[:screen] = ::Screen.joins(:theatre)
                            .find_by(id: params[:screen_id], theatres: { id: params[:theatre_id] })
      return true if ctx[:screen]

      ctx[:errors] = { screen: [ "Screen not found" ] }
      false
    end

    def find_layout(ctx, params:, screen:, **)
      ctx[:model] = screen.seat_layouts.find_by(id: params[:id])
      return true if ctx[:model]

      ctx[:errors] = { base: [ "Layout not found" ] }
      false
    end

    def authorize_layout(ctx, model:, current_user: nil, **)
      return true if Pundit.policy!(current_user, model).show?

      ctx[:errors] = { base: [ "Not authorized to view this layout" ] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end
  end
end
