module VenueOperationFixture
  def build_user(role:, email_prefix:, phone:)
    User.create!(
      name: "#{role.to_s.capitalize} #{SecureRandom.hex(3)}",
      email: "#{email_prefix}-#{SecureRandom.hex(4)}@example.com",
      password: "password",
      password_confirmation: "password",
      phone: phone,
      role: role,
      is_active: true
    )
  end

  def build_city
    City.create!(
      name: "City#{SecureRandom.hex(3)}",
      state: "State#{SecureRandom.hex(3)}"
    )
  end

  def build_theatre_for(vendor:, city:)
    Theatre.create!(
      vendor: vendor,
      city: city,
      name: "Theatre #{SecureRandom.hex(3)}",
      building_name: "Mall Plaza",
      street_address: "Main Street",
      pincode: "400001"
    )
  end

  def build_movie_stack
    language = Language.create!(name: "English #{SecureRandom.hex(2)}", code: "en#{Array.new(4) { ("a".."z").to_a.sample }.join}")
    format = Format.create!(name: "IMAX#{SecureRandom.hex(2)}", code: "imax#{SecureRandom.hex(2)}")
    movie = Movie.create!(
      title: "Movie #{SecureRandom.hex(4)}",
      genre: "Drama",
      rating: "UA",
      description: "A sufficiently descriptive movie summary for tests.",
      director: "Director Name",
      running_time: 120,
      release_date: Date.new(2026, 4, 1)
    )
    movie_language = MovieLanguage.create!(movie: movie, language: language, language_type: "original")
    movie_format = MovieFormat.create!(movie: movie, format: format)

    {
      movie: movie,
      language: language,
      format: format,
      movie_language: movie_language,
      movie_format: movie_format
    }
  end

  def build_published_layout_for(screen:, total_seats: 2)
    layout = SeatLayout.create!(
      screen: screen,
      name: "Published Layout",
      version_number: 1,
      status: "published",
      total_rows: 5,
      total_columns: 5,
      total_seats: total_seats,
      published_at: Time.current
    )

    section = SeatSection.create!(
      seat_layout: layout,
      code: "prime",
      name: "Prime",
      color_hex: "#FFAA00",
      rank: 1
    )

    { layout: layout, section: section }
  end
end

RSpec.configure do |config|
  config.include VenueOperationFixture
end
