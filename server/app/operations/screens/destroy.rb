module Screens
  class Destroy < ::Trailblazer::Operation
    step :find_theatre
    step :find_screen
    step :authorize_screen
    step :ensure_no_active_shows
    step :destroy
    fail :collect_errors

    def find_theatre(ctx, params:, **)
      ctx[:theatre] = ::Theatre.find_by(id: params[:theatre_id])
      unless ctx[:theatre]
        ctx[:errors] = { theatre: [ "Theatre not found" ] }
        return false
      end
      true
    end

    def find_screen(ctx, params:, theatre:, **)
      ctx[:model] = theatre.screens.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { screen: [ "Screen not found" ] }
        return false
      end
    true
    end

    def authorize_screen(ctx, model:, current_user:, **)
      return true if Pundit.policy!(current_user, model).destroy?

      ctx[:errors] = { base: [ "Not authorized to delete this screen" ] }
      false
    end

    def ensure_no_active_shows(ctx, model:, **)
      return true unless model.shows.where(status: "scheduled").where("end_time > ?", Time.current).exists?

      ctx[:errors] = { base: [ "Cannot delete a screen while it has running or upcoming shows" ] }
      false
    end

    def destroy(ctx, model:, **)
      model.destroy
    rescue ActiveRecord::DeleteRestrictionError
      ctx[:errors] = { base: [ "Cannot delete a screens that has seats or shows" ] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true).presence || { base: [ "Could not delete screen" ] }
    end
  end
end
