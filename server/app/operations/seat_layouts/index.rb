module SeatLayouts
  class Index < ::Trailblazer::Operation
    step :load_layouts

    def load_layouts(ctx, current_user: nil, params: {}, **)
      ctx[:records] = Pundit.policy_scope!(current_user, SeatLayout)
                           .where(screen_id: params[:screen_id])
                           .order(version_number: :desc)
    end
  end
end
