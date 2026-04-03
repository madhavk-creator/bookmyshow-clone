module ShowSeatStates
  class Lock < Trailblazer::Operation
    step :find_show
    step :validate_seats
    step :acquire_locks
    fail :collect_errors

    def find_show(ctx, params:, **)
      ctx[:show] = Show.find_by(id: params[:show_id])
      unless ctx[:show]&.status_scheduled?
        ctx[:errors] = { show: ['Show not found or not schedulable'] }
        return false
      end

      true
    end

    def validate_seats(ctx, params:, show:, **)
      seat_ids = Array(params[:seat_ids]).uniq

      if seat_ids.empty?
        ctx[:errors] = { seat_ids: ['No seats selected'] }
        return false
      end

      # All seats must belong to the show's layout and be active
      valid_seats = Seat.where(
        id:             seat_ids,
        seat_layout_id: show.seat_layout_id,
        is_active:      true
      )

      if valid_seats.count != seat_ids.count
        ctx[:errors] = { seat_ids: ['One or more seats are invalid for this show'] }
        return false
      end

      # None of the requested seats may already have a state row
      already_taken = ShowSeatState.where(show_id: show.id, seat_id: seat_ids).pluck(:seat_id, :status)
      if already_taken.any?
        taken_info = already_taken.map { |id, st| "#{id} (#{st})" }.join(', ')
        ctx[:errors] = { seat_ids: ["Seats no longer available: #{taken_info}"] }
        return false
      end

      ctx[:seats] = valid_seats
      true
    end

    def acquire_locks(ctx, params:, show:, seats:, **)
      lock_token  = params[:lock_token]
      locked_until = Time.current + ShowSeatState::LOCK_DURATION

      locked = []

      ShowSeatState.transaction do
        seats.each do |seat|
          locked << ShowSeatState.create!(
            show:              show,
            seat:              seat,
            status:            'locked',
            locked_by_user_id: params[:user_id],
            lock_token:        lock_token,
            locked_until:      locked_until
          )
        end
      end

      ctx[:locked_states] = locked
      true
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      ctx[:errors] = { seat_ids: ['Seats no longer available'] }
      false
    end

    def collect_errors(ctx, **)
      ctx[:errors] ||= { base: ['Could not acquire seat locks'] }
    end
  end
end
