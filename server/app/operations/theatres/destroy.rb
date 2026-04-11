module Theatres
  class Destroy < ::Trailblazer::Operation
    step :find_theatre
    step :authorize_theatre
    step :ensure_no_active_shows
    step :destroy
    fail :collect_errors

    def find_theatre(ctx, params:, model: nil, **)
      return true if model.present?

      ctx[:model] = Theatre.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: [ "Theatre not found" ] }
        return false
      end
      true
    end

    def authorize_theatre(ctx, model:, current_user:, **)
      return true if Pundit.policy!(current_user, model).destroy?

      ctx[:errors] = { base: [ "Not authorized to delete this theatre" ] }
      false
    end

    def ensure_no_active_shows(ctx, model:, **)
      active_show_exists = ::Show.joins(:screen)
                                .where(screens: { theatre_id: model.id }, status: "scheduled")
                                .where("shows.end_time > ?", Time.current)
                                .exists?
      return true unless active_show_exists

      ctx[:errors] = { base: [ "Cannot delete a theatre while it has running or upcoming shows" ] }
      false
    end

    def destroy(ctx, model:, **)
      model.destroy
    rescue ActiveRecord::DeleteRestrictionError
      ctx[:errors] = { base: [ "Cannot delete theatres with existing screens" ] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true).presence || { base: [ "Could not delete theatre" ] }
    end
  end
end
