module SeatLayouts
  class Archive < ::Trailblazer::Operation
    step :find_screen
    step :find_layout
    step :authorize_archive
    step :check_no_upcoming_shows
    step :archive
    fail :collect_errors

    def find_screen(ctx, params:, **)
      ctx[:screen] = ::Screen.joins(:theatre)
                            .find_by(id: params[:screen_id], theatres: { id: params[:theatre_id] })
      unless ctx[:screen]
        ctx[:errors] = { screen: [ "Screen not found" ] }
        return false
      end
      true
    end

    def find_layout(ctx, params:, screen:, **)
      ctx[:model] = screen.seat_layouts.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: [ "Layout not found" ] }
        return false
      end
      true
    end

    def authorize_archive(ctx, model:, current_user:, **)
      return true if Pundit.policy!(current_user, model).archive?

      ctx[:errors] = { base: [ "Not authorized to archive this layout" ] }
      false
    end

    def check_no_upcoming_shows(ctx, model:, **)
      upcoming = model.shows
                      .where(status: "scheduled")
                      .where("start_time > ?", Time.current)
                      .exists?
      if upcoming
        ctx[:errors] = { base: [ "Cannot archive a layout with upcoming scheduled shows" ] }
        return false
      end
      true
    end

    def archive(ctx, model:, **)
      model.status_archived!
    rescue ActiveRecord::RecordInvalid => e
      ctx[:errors] = { base: [ e.message ] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end
  end
end
