module Screens
  class Show < ::Trailblazer::Operation
    step :find_theatre
    step :find_screen
    step :authorize_screen
    fail :collect_errors

    def find_theatre(ctx, params:, **)
      ctx[:theatre] = ::Theatre.find_by(id: params[:theatre_id])
      return true if ctx[:theatre]

      ctx[:errors] = { theatre: [ "Theatre not found" ] }
      false
    end

    def find_screen(ctx, params:, theatre:, **)
      ctx[:model] = theatre.screens.includes(:formats).find_by(id: params[:id])
      return true if ctx[:model]

      ctx[:errors] = { screen: [ "Screen not found" ] }
      false
    end

    def authorize_screen(ctx, model:, current_user: nil, **)
      return true if Pundit.policy!(current_user, model).show?

      ctx[:errors] = { base: [ "Not authorized to view this screen" ] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end
  end
end
