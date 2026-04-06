module Shows
  # Only start_time and section prices can be updated on a scheduled show.
  # Changing start_time re-validates overlap.
  # layout, movie, language, and format are immutable after creation.

  class Update < ::Trailblazer::Operation
    step :find_show
    step :maybe_validate_overlap
    step :validate_section_prices
    step :assign_attributes
    step :persist_changes
    fail :collect_errors

    def find_show(ctx, params:, **)
      ctx[:model] = ::Show.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: [ "Show not found" ] }
        return false
      end
      true
    end

    def maybe_validate_overlap(ctx, params:, model:, **)
      return true unless params[:start_time].present?

      start_time = Time.zone.parse(params[:start_time].to_s)

      unless start_time
        ctx[:errors] = { start_time: [ "is invalid" ] }
        return false
      end

      end_time   = start_time + model.movie.running_time.minutes

      ctx[:new_start_time] = start_time
      ctx[:new_end_time]   = end_time

      overlap = ::Show.where(screen_id: model.screen_id, status: "scheduled")
                      .where.not(id: model.id)
                      .where("start_time < ? AND end_time > ?", end_time, start_time)
                      .exists?

      if overlap
        ctx[:errors] = { start_time: [ "This screen already has a show scheduled during this time" ] }
        return false
      end

      true
    end

    def assign_attributes(ctx, params:, model:, new_start_time: nil, new_end_time: nil, **)
      if new_start_time
        model.start_time = new_start_time
        model.end_time   = new_end_time
      end
    end

    def validate_section_prices(ctx, params:, model:, **)
      return true unless params.key?(:section_prices)

      price_entries = Array(params[:section_prices])
      layout_section_ids = model.seat_layout.seat_sections.pluck(:id).sort
      provided_ids = price_entries.map { |entry| entry[:seat_section_id] || entry["seat_section_id"] }.sort

      missing = layout_section_ids - provided_ids
      if missing.any?
        ctx[:errors] = { section_prices: [ "Missing prices for section IDs: #{missing.join(', ')}" ] }
        return false
      end

      extra = provided_ids - layout_section_ids
      if extra.any?
        ctx[:errors] = { section_prices: [ "Unknown section IDs for this layout: #{extra.join(', ')}" ] }
        return false
      end
    true
    end

    def persist_changes(ctx, params:, model:, **)
      model.class.transaction do
        model.save!

        next true unless params.key?(:section_prices)

        price_entries = Array(params[:section_prices])

        model.show_section_prices.destroy_all
        price_entries.each do |entry|
          model.show_section_prices.create!(
            seat_section_id: entry[:seat_section_id] || entry["seat_section_id"],
            base_price:      entry[:base_price]       || entry["base_price"]
          )
        end
      end

      true
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      ctx[:errors] = params.key?(:section_prices) ? { section_prices: [ e.message ] } : model.errors.to_hash(true)
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end
  end
end
