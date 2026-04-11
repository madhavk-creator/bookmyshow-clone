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
    expect(show.show_section_prices.first.base_price).to eq(250.0)
  end

  it "creates one daily show per date in the selected range" do
    vendor = create(:user, :vendor)
    screen = create(:screen, theatre: create(:theatre, vendor: vendor), total_seats: 2)
    movie = create(:movie, running_time: 150)
    movie_language = create(:movie_language, movie: movie)
    movie_format = create(:movie_format, movie: movie)
    create(:screen_capability, screen: screen, format: movie_format.format)
    layout = create(:seat_layout, :published, screen: screen, total_seats: 2)
    section = create(:seat_section, seat_layout: layout, code: "prime", name: "Prime", rank: 1)
    start_time = 2.days.from_now.change(hour: 16, min: 0)

    result = Shows::Create.call(
      current_user: vendor,
      params: {
        screen_id: screen.id,
        movie_id: movie.id,
        seat_layout_id: layout.id,
        movie_language_id: movie_language.id,
        movie_format_id: movie_format.id,
        start_time: start_time.iso8601,
        recurrence_end_date: (start_time.to_date + 6.days).iso8601,
        section_prices: [
          {
            seat_section_id: section.id,
            base_price: 250
          }
        ]
      }
    )

    expect(result).to be_success
    expect(result[:models].size).to eq(7)
    expect(result[:models].map(&:start_time)).to eq(
      (0..6).map { |offset| start_time + offset.days }
    )
    expect(Show.where(screen: screen).count).to eq(7)
    expect(ShowSectionPrice.joins(:show).where(shows: { screen_id: screen.id }).count).to eq(7)
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

  it "fails the whole recurring schedule when any occurrence overlaps" do
    vendor = create(:user, :vendor)
    screen = create(:screen, theatre: create(:theatre, vendor: vendor), total_seats: 2)
    movie = create(:movie, running_time: 150)
    movie_language = create(:movie_language, movie: movie)
    movie_format = create(:movie_format, movie: movie)
    create(:screen_capability, screen: screen, format: movie_format.format)
    layout = create(:seat_layout, :published, screen: screen, total_seats: 2)
    section = create(:seat_section, seat_layout: layout, code: "prime", name: "Prime", rank: 1)
    start_time = 2.days.from_now.change(hour: 16, min: 0)

    create(
      :show,
      screen: screen,
      seat_layout: layout,
      movie: movie,
      movie_language: movie_language,
      movie_format: movie_format,
      start_time: start_time + 2.days,
      end_time: start_time + 2.days + movie.running_time.minutes
    )

    result = Shows::Create.call(
      current_user: vendor,
      params: {
        screen_id: screen.id,
        movie_id: movie.id,
        seat_layout_id: layout.id,
        movie_language_id: movie_language.id,
        movie_format_id: movie_format.id,
        start_time: start_time.iso8601,
        recurrence_end_date: (start_time.to_date + 6.days).iso8601,
        section_prices: [
          {
            seat_section_id: section.id,
            base_price: 250
          }
        ]
      }
    )

    expect(result).not_to be_success
    expect(result[:errors]).to have_key(:start_time)
    expect(result[:errors][:start_time].first).to include((start_time + 2.days).strftime("%b %-d, %Y %-I:%M %p"))
    expect(Show.where(screen: screen).count).to eq(1)
  end
end
