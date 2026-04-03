module Screens
  class Index < Trailblazer::Operation
    step :load_screens

    def load_screens(ctx, current_user: nil, params: {}, **)
      ctx[:records] = Pundit.policy_scope!(current_user, Screen)
                           .where(theatre_id: params[:theatre_id])
                           .includes(:formats)
                           .order(:name)
    end
  end
end
