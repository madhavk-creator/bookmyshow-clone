module ShowSeatStates
  class Unblock < ::Trailblazer::Operation
    step :find_show
    step :authorize_unblock
    step :find_state
    step :validate_is_blocked
    step :delete_state
    fail :collect_errors

    def find_show(ctx, params:, **)
      ctx[:show] = ::Show.find_by(id: params[:show_id] || params[:id])
      return true if ctx[:show]

      ctx[:errors] = { show: [ "Show not found" ] }
      false
    end

    def authorize_unblock(ctx, current_user:, **)
      return true if Pundit.policy!(current_user, ::ShowSeatState).unblock?

      ctx[:errors] = { base: [ "Not authorized to unblock seats" ] }
      false
    end

    def find_state(ctx, params:, show:, **)
      ctx[:model] = ::ShowSeatState.find_by(
        show_id: show.id,
        seat_id: params[:seat_id]
      )
      unless ctx[:model]
        ctx[:errors] = { seat: [ "No block found for this seat" ] }
        return false
      end

      true
    end

    def validate_is_blocked(ctx, model:, **)
      unless model.status_blocked?
        ctx[:errors] = { seat: [ "Seat is #{model.status}, not blocked — cannot unblock" ] }
        return false
      end

      true
    end

    def delete_state(ctx, model:, **)
      model.destroy
      true
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= { base: [ "Could not unblock seat" ] }
    end
  end
end
