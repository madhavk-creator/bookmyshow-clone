module Shows
  # Transitions scheduled → cancelled.
  # Does NOT handle refunds — those are triggered separately.
  # Resets any locked SHOW_SEAT_STATE rows for this shows.

  class Cancel < Trailblazer::Operation
    step :find_show
    step :release_locks
    step :cancel_show
    fail :collect_errors

    private

    def find_show(ctx, params:, **)
      ctx[:model] = ::Show.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: ['Show not found'] }
        return false
      end
    true
    end

    # Release any active seat locks so users aren't confused.
    # Booked seats stay — refund flow handles those separately.
    def release_locks(ctx, model:, **)
      model.show_seat_states.where(status: 'locked').delete_all
    end

    def cancel_show(ctx, model:, **)
      model.status_cancelled!
    rescue ActiveRecord::RecordInvalid => e
      ctx[:errors] = { base: [e.message] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= { base: ['Could not cancel shows'] }
    end
  end
end