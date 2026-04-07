require "rails_helper"

RSpec.describe Shows::Create do
  it "creates a scheduled show with section prices" do
    vendor = create(:user, :vendor)
    screen = create(:screen, theatre: create(:theatre, vendor: vendor), total_seats: 2)
    movie = create(:movie)
    movie_language = create(:movie_language, movie: movie)
    movie_format = create(:movie_format, movie: movie)
    create(:screen_capability, screen: screen, format: movie_format.format)
    layout = create(:seat_layout, :published, screen: screen, total_seats: 2)
    section = create(:seat_section, seat_layout: layout, code: "prime", name: "Prime", rank: 1)

    result = Shows::Create.call(
      current_user: vendor,
      params: {
        screen_id: screen.id,
        movie_id: movie.id,
        seat_layout_id: layout.id,
        movie_language_id: movie_language.id,
        movie_format_id: movie_format.id,
        start_time: 2.days.from_now.iso8601,
        section_prices: [
          {
            seat_section_id: section.id,
            base_price: 250
          }
        ]
      }
    )

    expect(result).to be_success
    show = result[:model]
    expect(show.status).to eq("scheduled")
    expect(show.screen).to eq(screen)
    expect(show.movie).to eq(movie)
    expect(show.show_section_prices.count).to eq(1)
    expect(show.show_section_prices.first.base_price.to_d).to eq(250.to_d)
  end

  it "fails when section prices are missing for a layout section" do
    vendor = create(:user, :vendor)
    screen = create(:screen, theatre: create(:theatre, vendor: vendor), total_seats: 2)
    movie = create(:movie)
    movie_language = create(:movie_language, movie: movie)
    movie_format = create(:movie_format, movie: movie)
    create(:screen_capability, screen: screen, format: movie_format.format)
    layout = create(:seat_layout, :published, screen: screen, total_seats: 2)
    create(:seat_section, seat_layout: layout, code: "prime", name: "Prime", rank: 1)
    balcony = create(:seat_section, seat_layout: layout, code: "balcony", name: "Balcony", rank: 2)

    result = Shows::Create.call(
      current_user: vendor,
      params: {
        screen_id: screen.id,
        movie_id: movie.id,
        seat_layout_id: layout.id,
        movie_language_id: movie_language.id,
        movie_format_id: movie_format.id,
        start_time: 2.days.from_now.iso8601,
        section_prices: [
          {
            seat_section_id: balcony.id,
            base_price: 300
          }
        ]
      }
    )

    expect(result).not_to be_success
    expect(result[:errors]).to have_key(:section_prices)
  end
end
