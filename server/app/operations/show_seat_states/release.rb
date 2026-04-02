module ShowSeatStates
  class Release < Trailblazer::Operation
    step :release_locks
    fail :collect_errors

    private

    def release_locks(ctx, params:, **)
      deleted = ShowSeatState.where(
        lock_token: params[:lock_token],
        status:     'locked'
      ).delete_all

      ctx[:released_count] = deleted
      true
    end

    def collect_errors(ctx, **)
      ctx[:errors] = { base: ['Could not release locks'] }
    end
  end
end