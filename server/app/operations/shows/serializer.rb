module Shows
  module Serializer
    module_function

    def call(show, detailed: false)
      base = {
        id: show.id,
        screen_id: show.screen_id,
        screen: {
          id: show.screen.id,
          name: show.screen.name,
          theatre: {
            id: show.screen.theatre.id,
            name: show.screen.theatre.name,
            building_name: show.screen.theatre.building_name,
            street_address: show.screen.theatre.street_address
          }
        },
        movie: {
          id: show.movie.id,
          title: show.movie.title,
          running_time: show.movie.running_time
        },
        language: {
          id: show.movie_language.id,
          code: show.movie_language.language.code
        },
        format: {
          id: show.movie_format.id,
          code: show.movie_format.format.code
        },
        seat_layout_id: show.seat_layout_id,
        start_time: show.start_time,
        end_time: show.end_time,
        total_capacity: show.total_capacity,
        status: show.status
      }

      return base unless detailed

      base[:section_prices] = show.show_section_prices.map do |price|
        {
          seat_section_id: price.seat_section_id,
          seat_section_code: price.seat_section.code,
          seat_section_name: price.seat_section.name,
          base_price: price.base_price
        }
      end

      base
    end

    def many(shows, detailed: false)
      shows.map { |show| call(show, detailed: detailed) }
    end
  end
end
