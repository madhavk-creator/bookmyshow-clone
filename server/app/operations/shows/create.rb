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
#   start_time, recurrence_end_date: (optional YYYY-MM-DD),
#   section_prices: [{ seat_section_id: uuid, base_price: decimal }, ...]

module Shows
  class Create < ::Trailblazer::Operation
    step :find_screen
    step :authorize_screen
    step :find_movie
    step :find_layout
    step :find_movie_language
    step :find_movie_format
    step :validate_format_capability
    step :build_schedule_times
    step :validate_no_overlap
    step :build_shows
    step :validate_section_prices
    step :persist_shows_with_prices
    fail :collect_errors

    def find_screen(ctx, params:, **)
      ctx[:screen] = Screen.find_by(id: params[:screen_id])
      unless ctx[:screen]&.active?
        ctx[:errors] = { screen: [ "Screen not found or inactive" ] }
        return false
      end
    true
    end

    def authorize_screen(ctx, screen:, current_user:, **)
      record = ::Show.new(screen: screen)
      return true if Pundit.policy!(current_user, record).create?

      ctx[:errors] = { base: [ "Not authorized to create show for this screen" ] }
      false
    end

    def find_movie(ctx, params:, **)
      ctx[:movie] = Movie.find_by(id: params[:movie_id])
      unless ctx[:movie]
        ctx[:errors] = { movie: [ "Movie not found" ] }
        return false
      end
    true
    end

    def find_layout(ctx, params:, screen:, **)
      ctx[:layout] = SeatLayout.find_by(id: params[:seat_layout_id])

      unless ctx[:layout]
        ctx[:errors] = { seat_layout_id: [ "Layout not found" ] }
        return false
      end

      unless ctx[:layout].screen_id == screen.id
        ctx[:errors] = { seat_layout_id: [ "Layout does not belong to this screens" ] }
        return false
      end

      unless ctx[:layout].status_published?
        ctx[:errors] = { seat_layout_id: [ "Only published layouts can be used for shows" ] }
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
        ctx[:errors] = { movie_language_id: [ "Language not found for this movies" ] }
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
        ctx[:errors] = { movie_format_id: [ "Format not found for this movies" ] }
        return false
      end
    true
    end

    # The screen must have a capability matching the movie's chosen format.
    def validate_format_capability(ctx, screen:, movie_format:, **)
      supported = screen.screen_capabilities
                        .exists?(format_id: movie_format.format_id)
      unless supported
        ctx[:errors] = { movie_format_id: [ "This screens does not support the selected formats" ] }
        return false
      end
    true
    end

    def build_schedule_times(ctx, params:, **)
      start_time = Time.zone.parse(params[:start_time].to_s)

      unless start_time
        ctx[:errors] = { start_time: [ "is invalid" ] }
        return false
      end

      recurrence_end_date = parse_recurrence_end_date(params[:recurrence_end_date])
      if recurrence_end_date == :invalid
        ctx[:errors] = { recurrence_end_date: [ "is invalid" ] }
        return false
      end

      if recurrence_end_date && recurrence_end_date < start_time.to_date
        ctx[:errors] = { recurrence_end_date: [ "must be on or after the start date" ] }
        return false
      end

      ctx[:schedule_times] =
        if recurrence_end_date
          (start_time.to_date..recurrence_end_date).map do |date|
            Time.zone.local(
              date.year,
              date.month,
              date.day,
              start_time.hour,
              start_time.min,
              start_time.sec
            )
          end
        else
          [ start_time ]
        end

      true
    end

    # No two scheduled shows on the same screens may overlap.
    # Overlap condition: existing.start_time < new.end_time AND existing.end_time > new.start_time
    def validate_no_overlap(ctx, screen:, movie:, schedule_times:, **)
      conflicts = schedule_times.filter_map do |start_time|
        end_time = start_time + movie.running_time.minutes

        overlap = ::Show.where(screen_id: screen.id, status: "scheduled")
                        .where("start_time < ? AND end_time > ?", end_time, start_time)
                        .exists?

        start_time if overlap
      end

      if conflicts.any?
        formatted_conflicts = conflicts.map { |time| time.strftime("%b %-d, %Y %-I:%M %p") }.join(", ")
        ctx[:errors] = { start_time: [ "This screen already has a show scheduled during: #{formatted_conflicts}" ] }
        return false
      end

      true
    end

    def build_shows(ctx, screen:, movie:, layout:, movie_language:, movie_format:, schedule_times:, **)
      ctx[:models] = schedule_times.map do |start_time|
        ::Show.new(
          screen:           screen,
          movie:            movie,
          seat_layout:      layout,
          movie_language:   movie_language,
          movie_format:     movie_format,
          start_time:       start_time,
          end_time:         start_time + movie.running_time.minutes,
          total_capacity:   layout.total_seats,
          status:           "scheduled"
        )
      end

      ctx[:model] = ctx[:models].first
    end

    # Every section in the layout must have a price entry.
    # section_prices: [{ seat_section_id: uuid, base_price: decimal }]
    def validate_section_prices(ctx, params:, layout:, **)
      price_entries = Array(params[:section_prices])

      if price_entries.empty?
        ctx[:errors] = { section_prices: [ "Section prices are required" ] }
        return false
      end

      layout_section_ids = layout.seat_sections.pluck(:id).sort
      provided_ids       = price_entries.map { |e| e[:seat_section_id] || e["seat_section_id"] }.sort

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

    def persist_shows_with_prices(ctx, params:, models:, **)
      price_entries = Array(params[:section_prices])

      ::Show.transaction do
        models.each do |model|
          model.save!

          price_entries.each do |entry|
            model.show_section_prices.create!(
              seat_section_id: entry[:seat_section_id] || entry["seat_section_id"],
              base_price:      entry[:base_price]       || entry["base_price"]
            )
          end
        end
      end

      true
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      ctx[:errors] = { section_prices: [ e.message ] }
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end

    private

    def parse_recurrence_end_date(value)
      return nil if value.blank?

      Date.parse(value.to_s)
    rescue ArgumentError
      :invalid
    end
  end
end
