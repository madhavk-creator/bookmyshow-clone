# Transitions draft → published.
# Guards:
#   - must have at least one section
#   - must have at least one active seat
#   - total_seats on the layout must match actual active seat count
#   - partial unique index enforces one published layout per screens at DB level
module SeatLayouts
  class Publish < Trailblazer::Operation
    step :find_layout
    step :validate_has_sections
    step :validate_has_seats
    step :publish
    fail :collect_errors

    def find_layout(ctx, params:, **)
      ctx[:model] = ::SeatLayout.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: ['Layout not found'] }
        return false
      end
      true
    end

    def validate_has_sections(ctx, model:, **)
      unless model.seat_sections.exists?
        ctx[:errors] = { base: ['Layout must have at least one section before publishing'] }
        return false
      end
      true
    end

    def validate_has_seats(ctx, model:, **)
      unless model.seats.where(is_active: true).exists?
        ctx[:errors] = { base: ['Layout must have at least one active seat before publishing'] }
        return false
      end
      true
    end

    def publish(ctx, model:, **)
      active_count = model.seats.where(is_active: true).count

      model.class.transaction do
        model.update!(
          status: "published",
          published_at: Time.current,
          total_seats: active_count
        )
        model.screen.update!(total_seats: active_count)
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      ctx[:errors] = { base: [e.message] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end
  end
end
