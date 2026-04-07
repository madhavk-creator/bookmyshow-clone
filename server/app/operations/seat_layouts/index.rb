module SeatLayouts
  class Index < ::Trailblazer::Operation
    step :find_screen
    step :load_layouts

    def find_screen(ctx, params:, **)
      ctx[:screen] = ::Screen.joins(:theatre)
                            .find_by(id: params[:screen_id], theatres: { id: params[:theatre_id] })
      return true if ctx[:screen]

      ctx[:errors] = { screen: [ "Screen not found" ] }
      false
    end

    def load_layouts(ctx, current_user: nil, params: {}, **)
      ctx[:records] = Pundit.policy_scope!(current_user, SeatLayout)
                           .where(screen_id: params[:screen_id])
                           .order(version_number: :desc)
    end
  end
end
