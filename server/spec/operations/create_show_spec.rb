require "rails_helper"

RSpec.describe Shows::Create do
  it "creates a scheduled show with section prices" do
    vendor = build_user(role: :vendor, email_prefix: "vendor", phone: "9876543210")
    city = build_city
    theatre = build_theatre_for(vendor: vendor, city: city)
    screen = Screen.create!(
      theatre: theatre,
      name: "Screen #{SecureRandom.hex(2)}",
      total_rows: 5,
      total_columns: 5,
      total_seats: 2,
      status: "active"
    )
    movie_stack = build_movie_stack
    ScreenCapability.create!(screen: screen, format: movie_stack[:format])
    layout_stack = build_published_layout_for(screen: screen, total_seats: 2)

    result = Shows::Create.call(
      params: {
        screen_id: screen.id,
        movie_id: movie_stack[:movie].id,
        seat_layout_id: layout_stack[:layout].id,
        movie_language_id: movie_stack[:movie_language].id,
        movie_format_id: movie_stack[:movie_format].id,
        start_time: 2.days.from_now.iso8601,
        section_prices: [
          {
            seat_section_id: layout_stack[:section].id,
            base_price: 250
          }
        ]
      }
    )

    expect(result).to be_success
    show = result[:model]
    expect(show.status).to eq("scheduled")
    expect(show.screen).to eq(screen)
    expect(show.movie).to eq(movie_stack[:movie])
    expect(show.show_section_prices.count).to eq(1)
    expect(show.show_section_prices.first.base_price.to_d).to eq(250.to_d)
  end
end
