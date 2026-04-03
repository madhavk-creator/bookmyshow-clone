module ShowSeatStates
  class Block < Trailblazer::Operation
    step :find_show
    step :find_seat
    step :validate_seat_available
    step :create_block
    fail :collect_errors

    def find_show(ctx, params:, **)
      ctx[:show] = Show.find_by(id: params[:show_id])
      unless ctx[:show]
        ctx[:errors] = { show: ['Show not found'] }
        return false
      end
    end

    def find_seat(ctx, params:, show:, **)
      ctx[:seat] = Seat.find_by(id: params[:seat_id], seat_layout_id: show.seat_layout_id)
      unless ctx[:seat]&.is_active?
        ctx[:errors] = { seat: ['Seat not found or inactive for this show'] }
        return false
      end
    end

    def validate_seat_available(ctx, params:, show:, **)
      existing = ShowSeatState.find_by(show_id: show.id, seat_id: params[:seat_id])
      if existing
        ctx[:errors] = { seat: ["Seat is already #{existing.status} — cannot block"] }
        return false
      end
    end

    def create_block(ctx, show:, seat:, **)
      ctx[:model] = ShowSeatState.create!(
        show:   show,
        seat:   seat,
        status: 'blocked'
      )
    rescue ActiveRecord::RecordInvalid => e
      ctx[:errors] = { base: [e.message] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end
  end
end
