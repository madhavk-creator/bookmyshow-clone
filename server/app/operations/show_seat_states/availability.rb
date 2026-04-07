module ShowSeatStates
  class Availability < ::Trailblazer::Operation
    step :find_show
    step :authorize_availability
    step :release_expired_locks
    step :build_payload
    fail :collect_errors

    def find_show(ctx, params:, **)
      ctx[:show] = ::Show.find_by(id: params[:show_id] || params[:id])
      return true if ctx[:show]

      ctx[:errors] = { show: [ "Show not found" ] }
      false
    end

    def authorize_availability(ctx, show:, current_user: nil, **)
      return true if Pundit.policy!(current_user, ShowSeatState).availability?

      ctx[:errors] = { base: [ "Not authorized to view seat availability" ] }
      false
    end

    def release_expired_locks(_ctx, show:, **)
      show.release_expired_locks!
      true
    end

    def build_payload(ctx, show:, **)
      layout   = show.seat_layout
      sections = layout.seat_sections.order(:rank).includes(:seats)

      state_by_seat_id = ::ShowSeatState
                           .for_show(show.id)
                           .index_by(&:seat_id)
                           .to_h

      price_by_section_id = ::ShowSectionPrice
                              .where(show_id: show.id)
                              .pluck(:seat_section_id, :base_price)
                              .to_h

      counts = { available: 0, locked: 0, booked: 0, blocked: 0, inactive: 0 }

      serialized_sections = sections.map do |section|
        seats = section.seats.order(:grid_row, :grid_column)

        serialized_seats = seats.map do |seat|
          state = state_by_seat_id[seat.id]
          status = !seat.is_active ? "inactive" : (state ? state.effective_status : "available")
          counts[status.to_sym] += 1

          {
            id:            seat.id,
            label:         seat.label,
            row_label:     seat.row_label,
            seat_number:   seat.seat_number,
            grid_row:      seat.grid_row,
            grid_column:   seat.grid_column,
            x_span:        seat.x_span,
            y_span:        seat.y_span,
            seat_kind:     seat.seat_kind,
            is_accessible: seat.is_accessible,
            status:        status
          }
        end

        {
          id:         section.id,
          code:       section.code,
          name:       section.name,
          color_hex:  section.color_hex,
          rank:       section.rank,
          base_price: price_by_section_id[section.id],
          seats:      serialized_seats
        }
      end

      ctx[:payload] = {
        show_id:         show.id,
        total_capacity:  show.total_capacity,
        available_count: counts[:available],
        locked_count:    counts[:locked],
        booked_count:    counts[:booked],
        blocked_count:   counts[:blocked],
        inactive_count:  counts[:inactive],
        sections:        serialized_sections
      }
      true
    end

    def collect_errors(ctx, **)
      ctx[:errors] ||= { base: [ "Could not load seat availability" ] }
    end
  end
end
