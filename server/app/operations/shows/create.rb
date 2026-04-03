# Validations enforced:
#   1. Screen must be active
#   2. Layout must be published and belong to the screens
#   3. Movie formats must be supported by screens capabilities
#   4. movie_language_id must belong to the movies
#   5. movie_format_id must belong to the movies
#   6. No overlapping shows on the same screens
#   7. end_time is derived — never supplied by the client
#   8. SHOW_SECTION_PRICE must cover every section in the layout
#
# Params:
#   screen_id, movie_id, seat_layout_id, movie_language_id, movie_format_id,
#   start_time,
#   section_prices: [{ seat_section_id: uuid, base_price: decimal }, ...]

module Shows
  class Create < Trailblazer::Operation
    step :find_screen
    step :find_movie
    step :find_layout
    step :find_movie_language
    step :find_movie_format
    step :validate_format_capability
    step :validate_no_overlap
    step :build_show
    step :validate_section_prices
    step :persist_show_with_prices
    fail :collect_errors

    def find_screen(ctx, params:, **)
      ctx[:screen] = Screen.find_by(id: params[:screen_id])
      unless ctx[:screen]&.active?
        ctx[:errors] = { screen: ['Screen not found or inactive'] }
        return false
      end
    true
    end

    def find_movie(ctx, params:, **)
      ctx[:movie] = Movie.find_by(id: params[:movie_id])
      unless ctx[:movie]
        ctx[:errors] = { movie: ['Movie not found'] }
        return false
      end
    true
    end

    def find_layout(ctx, params:, screen:, **)
      ctx[:layout] = SeatLayout.find_by(id: params[:seat_layout_id])

      unless ctx[:layout]
        ctx[:errors] = { seat_layout_id: ['Layout not found'] }
        return false
      end

      unless ctx[:layout].screen_id == screen.id
        ctx[:errors] = { seat_layout_id: ['Layout does not belong to this screens'] }
        return false
      end

      unless ctx[:layout].status_published?
        ctx[:errors] = { seat_layout_id: ['Only published layouts can be used for shows'] }
        return false
      end
    true
    end

    def find_movie_language(ctx, params:, movie:, **)
      ctx[:movie_language] = MovieLanguage.find_by(
        id:       params[:movie_language_id],
        movie_id: movie.id
      )
      unless ctx[:movie_language]
        ctx[:errors] = { movie_language_id: ['Language not found for this movies'] }
        return false
      end
    true
    end

    def find_movie_format(ctx, params:, movie:, **)
      ctx[:movie_format] = MovieFormat.find_by(
        id:       params[:movie_format_id],
        movie_id: movie.id
      )
      unless ctx[:movie_format]
        ctx[:errors] = { movie_format_id: ['Format not found for this movies'] }
        return false
      end
    true
    end

    # The screen must have a capability matching the movie's chosen format.
    def validate_format_capability(ctx, screen:, movie_format:, **)
      supported = screen.screen_capabilities
                        .exists?(format_id: movie_format.format_id)
      unless supported
        ctx[:errors] = { movie_format_id: ['This screens does not support the selected formats'] }
        return false
      end
    true
    end

    # No two scheduled shows on the same screens may overlap.
    # Overlap condition: existing.start_time < new.end_time AND existing.end_time > new.start_time
    def validate_no_overlap(ctx, params:, screen:, movie:, **)
      start_time = Time.zone.parse(params[:start_time].to_s)

      unless start_time
        ctx[:errors] = { start_time: ['is invalid'] }
        return false
      end

      end_time   = start_time + movie.running_time.minutes

      ctx[:start_time] = start_time
      ctx[:end_time]   = end_time

      overlap = ::Show.where(screen_id: screen.id, status: 'scheduled')
                      .where('start_time < ? AND end_time > ?', end_time, start_time)
                      .exists?

      if overlap
        ctx[:errors] = { start_time: ['This screen already has a show scheduled during this time'] }
        return false
      end

      true
    end

    def build_show(ctx, params:, screen:, movie:, layout:, movie_language:, movie_format:, start_time:, end_time:, **)
      ctx[:model] = ::Show.new(
        screen:           screen,
        movie:            movie,
        seat_layout:      layout,
        movie_language:   movie_language,
        movie_format:     movie_format,
        start_time:       start_time,
        end_time:         end_time,
        total_capacity:   layout.total_seats,
        status:           'scheduled'
      )
    end

    # Every section in the layout must have a price entry.
    # section_prices: [{ seat_section_id: uuid, base_price: decimal }]
    def validate_section_prices(ctx, params:, layout:, **)
      price_entries = Array(params[:section_prices])

      if price_entries.empty?
        ctx[:errors] = { section_prices: ['Section prices are required'] }
        return false
      end

      layout_section_ids = layout.seat_sections.pluck(:id).sort
      provided_ids       = price_entries.map { |e| e[:seat_section_id] || e['seat_section_id'] }.sort

      missing = layout_section_ids - provided_ids
      if missing.any?
        ctx[:errors] = { section_prices: ["Missing prices for section IDs: #{missing.join(', ')}"] }
        return false
      end

      extra = provided_ids - layout_section_ids
      if extra.any?
        ctx[:errors] = { section_prices: ["Unknown section IDs for this layout: #{extra.join(', ')}"] }
        return false
      end
    true
    end

    def persist_show_with_prices(ctx, params:, model:, **)
      price_entries = Array(params[:section_prices])

      model.class.transaction do
        model.save!

        price_entries.each do |entry|
          model.show_section_prices.create!(
            seat_section_id: entry[:seat_section_id] || entry['seat_section_id'],
            base_price:      entry[:base_price]       || entry['base_price']
          )
        end
      end

      true
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      ctx[:errors] = { section_prices: [e.message] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end
  end
end
