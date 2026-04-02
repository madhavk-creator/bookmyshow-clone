module ShowSeatStates
  class Unblock < Trailblazer::Operation
    step :find_state
    step :validate_is_blocked
    step :delete_state
    fail :collect_errors

    private

    def find_state(ctx, params:, **)
      ctx[:model] = ShowSeatState.find_by(
        show_id: params[:show_id],
        seat_id: params[:seat_id]
      )
      unless ctx[:model]
        ctx[:errors] = { seat: ['No block found for this seat'] }
        return false
      end
    end

    def validate_is_blocked(ctx, model:, **)
      unless model.status_blocked?
        ctx[:errors] = { seat: ["Seat is #{model.status}, not blocked — cannot unblock"] }
        return false
      end
    end

    def delete_state(ctx, model:, **)
      model.destroy
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= { base: ['Could not unblock seat'] }
    end
  end
end