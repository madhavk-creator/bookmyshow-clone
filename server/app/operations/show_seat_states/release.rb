module ShowSeatStates
  class Release < ::Trailblazer::Operation
    step :release_locks
    fail :collect_errors

    def release_locks(ctx, params:, **)
      scope = ShowSeatState.where(
        lock_token: params[:lock_token],
        status:     "locked"
      )
      scope = scope.where(seat_id: params[:seat_ids]) if params[:seat_ids].present?

      deleted = scope.delete_all

      ctx[:released_count] = deleted
      true
    end

    def collect_errors(ctx, **)
      ctx[:errors] = { base: [ "Could not release locks" ] }
    end
  end
end
