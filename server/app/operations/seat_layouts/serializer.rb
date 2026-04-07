module SeatLayouts
  module Serializer
    module_function

    def call(layout, detailed: false)
      base = {
        id: layout.id,
        screen_id: layout.screen_id,
        version_number: layout.version_number,
        name: layout.name,
        status: layout.status,
        total_rows: layout.total_rows,
        total_columns: layout.total_columns,
        total_seats: layout.total_seats,
        screen_label: layout.screen_label,
        published_at: layout.published_at,
        created_at: layout.created_at
      }

      return base unless detailed

      sections = layout.seat_sections.order(:rank).includes(:seats)
      base[:sections] = sections.map do |section|
        {
          id: section.id,
          code: section.code,
          name: section.name,
          color_hex: section.color_hex,
          rank: section.rank,
          seat_type: section.seat_type,
          seats: section.seats.order(:grid_row, :grid_column).map { |seat| serialize_seat(seat) }
        }
      end

      base
    end

    def many(layouts, detailed: false)
      layouts.map { |layout| call(layout, detailed: detailed) }
    end

    def serialize_seat(seat)
      {
        id: seat.id,
        label: seat.label,
        row_label: seat.row_label,
        seat_number: seat.seat_number,
        grid_row: seat.grid_row,
        grid_column: seat.grid_column,
        x_span: seat.x_span,
        y_span: seat.y_span,
        seat_kind: seat.seat_kind,
        is_accessible: seat.is_accessible,
        is_active: seat.is_active
      }
    end
  end
end
