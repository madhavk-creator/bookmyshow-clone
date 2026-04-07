module Screens
  class Index < ::Trailblazer::Operation
    step :find_theatre
    step :load_screens

    def find_theatre(ctx, params:, **)
      ctx[:theatre] = ::Theatre.find_by(id: params[:theatre_id])
      return true if ctx[:theatre]

      ctx[:errors] = { theatre: [ "Theatre not found" ] }
      false
    end

    def load_screens(ctx, current_user: nil, params: {}, **)
      ctx[:records] = Pundit.policy_scope!(current_user, Screen)
                           .where(theatre_id: params[:theatre_id])
                           .includes(:formats)
                           .order(:name)
    end
  end
end
