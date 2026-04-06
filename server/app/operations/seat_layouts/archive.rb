module SeatLayouts
  class Archive < ::Trailblazer::Operation
    step :find_layout
    step :check_no_upcoming_shows
    step :archive
    fail :collect_errors

    def find_layout(ctx, params:, **)
      ctx[:model] = ::SeatLayout.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: [ "Layout not found" ] }
        return false
      end
      true
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
