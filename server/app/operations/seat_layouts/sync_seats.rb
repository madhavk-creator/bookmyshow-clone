# Replace-on-write for seats within a layout.
# Sections must already exist before syncing seats.
#
# Params: id, seats: [{ row_label:, seat_number:, grid_row:, grid_column:,
#                        seat_section_id:, seat_kind:, x_span:, y_span:,
#                        is_accessible:, is_active: }, ...]
#
# The frontend grid editor sends the full seat map on save.
# label is auto-derived by Seat's before_validation callback.
module SeatLayouts
  class SyncSeats < Trailblazer::Operation
    step :find_layout
    step :validate_sections_exist
    step :validate_seat_sections_belong_to_layout
    step :replace_seats
    step :update_layout_seat_count
    fail :collect_errors

    private

    def find_layout(ctx, params:, **)
      ctx[:model] = ::SeatLayout.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: ['Layout not found'] }
        return false
      end
      true
    end

    def validate_sections_exist(ctx, model:, **)
      unless model.seat_sections.exists?
        ctx[:errors] = { base: ['Add sections before adding seats'] }
        return false
      end
      true
    end

    def validate_seat_sections_belong_to_layout(ctx, params:, model:, **)
      seat_entries    = Array(params[:seats])
      section_ids     = seat_entries.map { |s| s[:seat_section_id] || s['seat_section_id'] }.compact.uniq
      valid_ids       = model.seat_sections.where(id: section_ids).pluck(:id)
      invalid         = section_ids - valid_ids

      if invalid.any?
        ctx[:errors] = { seats: ["Section IDs do not belong to this layout: #{invalid.join(', ')}"] }
        return false
      end
      true
    end

    def replace_seats(ctx, params:, model:, **)
      seats = Array(params[:seats])
      new_seats = seats.map do |s|
        Seat.new(
          seat_layout:     model,
          seat_section_id: s[:seat_section_id] || s['seat_section_id'],
          row_label:       s[:row_label]        || s['row_label'],
          seat_number:     s[:seat_number]      || s['seat_number'],
          grid_row:        s[:grid_row]         || s['grid_row'],
          grid_column:     s[:grid_column]      || s['grid_column'],
          x_span:          s[:x_span]           || s['x_span'] || 1,
          y_span:          s[:y_span]           || s['y_span'] || 1,
          seat_kind:       s[:seat_kind]        || s['seat_kind'] || 'standard',
          is_accessible:   s.fetch(:is_accessible, s.fetch('is_accessible', false)),
          is_active:       s.fetch(:is_active,    s.fetch('is_active',    true))
        )
      end

      invalid_seat = new_seats.find { |seat| !seat.valid? }
      if invalid_seat
        ctx[:errors] = invalid_seat.errors.to_hash(true)
        return false
      end

      Seat.transaction do
        Seat.where(seat_layout_id: model.id).destroy_all
        new_seats.each(&:save!)
        model.update!(total_seats: new_seats.count(&:is_active))
      end

      true
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      ctx[:errors] = { seats: [e.message] }
      false
    end

    # Update the draft layout's total_seats count after replacing seats.
    # The authoritative sync happens again at publish time.
    def update_layout_seat_count(ctx, model:, **)
      true
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= { base: ['Could not sync seats'] }
    end
  end
end
