# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "Seeding development data..."

ActiveRecord::Base.transaction do
  def ensure_language!(code:, name:)
    normalized_code = code.to_s.strip.downcase
    normalized_name = name.to_s.strip.titleize

    language = Language.find_by(code: normalized_code) ||
               Language.where("LOWER(name) = ?", normalized_name.downcase).first ||
               Language.new

    if language.new_record?
      language.code = normalized_code
      language.name = normalized_name
      language.save!
      return language
    end

    if language.code != normalized_code && !Language.where(code: normalized_code).where.not(id: language.id).exists?
      language.code = normalized_code
    end

    if language.name != normalized_name && !Language.where("LOWER(name) = ?", normalized_name.downcase).where.not(id: language.id).exists?
      language.name = normalized_name
    end

    language.save! if language.changed?
    language
  end

  def ensure_format!(code:, name:)
    normalized_code = code.to_s.strip.downcase
    normalized_name = name.to_s.strip.upcase

    format = Format.find_by(code: normalized_code) ||
             Format.where("UPPER(name) = ?", normalized_name).first ||
             Format.new

    if format.new_record?
      format.code = normalized_code
      format.name = normalized_name
      format.save!
      return format
    end

    if format.code != normalized_code && !Format.where(code: normalized_code).where.not(id: format.id).exists?
      format.code = normalized_code
    end

    if format.name != normalized_name && !Format.where("UPPER(name) = ?", normalized_name).where.not(id: format.id).exists?
      format.name = normalized_name
    end

    format.save! if format.changed?
    format
  end

  def upsert_user(email:, name:, phone:, role:, password:)
    user = User.find_or_initialize_by(email: email)
    user.assign_attributes(
      name: name,
      phone: phone,
      role: role,
      is_active: true
    )
    user.password = password if user.new_record?
    user.password_confirmation = password if user.new_record?
    user.save!
    user
  end

  def upsert_movie(movie_attrs, language_specs:, format_codes:, cast_specs:)
    movie = Movie.find_or_initialize_by(title: movie_attrs[:title])
    movie.assign_attributes(movie_attrs)
    movie.save!

    existing_languages = movie.movie_languages.includes(:language).index_by { |entry| entry.language.code }
    language_specs.each do |spec|
      language = ensure_language!(code: spec.fetch(:code), name: spec.fetch(:name))
      movie_language = existing_languages[language.code] || movie.movie_languages.build(language: language)
      movie_language.language_type = spec.fetch(:language_type)
      movie_language.save!
    end

    existing_formats = movie.movie_formats.includes(:format).index_by { |entry| entry.format.code }
    format_codes.each do |code|
      format = ensure_format!(code: code, name: code)
      movie_format = existing_formats[format.code] || movie.movie_formats.build(format: format)
      movie_format.save!
    end

    cast_specs.each do |cast_attrs|
      cast_member = movie.cast_members.find_or_initialize_by(
        name: cast_attrs.fetch(:name),
        role: cast_attrs.fetch(:role)
      )
      cast_member.assign_attributes(cast_attrs)
      cast_member.save!
    end

    movie
  end

  def sync_sections(layout, section_specs)
    section_specs.map do |spec|
      section = layout.seat_sections.find_or_initialize_by(code: spec.fetch(:code))
      section.assign_attributes(spec)
      section.save!
      section
    end
  end

  def sync_seats(layout, section_map, rows:)
    total_columns = rows.map { |row| row.fetch(:seat_numbers).max }.max

    rows.each_with_index do |row, row_index|
      section = section_map.fetch(row.fetch(:section_code))
      row_label = row.fetch(:row_label)

      row.fetch(:seat_numbers).each do |seat_number|
        seat = layout.seats.find_or_initialize_by(row_label: row_label, seat_number: seat_number)
        seat.assign_attributes(
          seat_layout: layout,
          seat_section: section,
          grid_row: row_index,
          grid_column: seat_number - 1,
          seat_kind: row[:seat_kind] || "standard",
          is_accessible: Array(row[:accessible_numbers]).include?(seat_number),
          is_active: true,
          x_span: 1,
          y_span: 1
        )
        seat.save!
      end
    end

    layout.update!(
      total_rows: rows.size,
      total_columns: total_columns,
      total_seats: rows.sum { |row| row.fetch(:seat_numbers).size }
    )
  end

  def upsert_layout(screen:, name:, rows:, section_specs:)
    layout = screen.seat_layouts.where(name: name).first_or_initialize
    layout.assign_attributes(
      screen_label: screen.name,
      status: "published",
      published_at: layout.published_at || Time.current,
      total_rows: rows.size,
      total_columns: rows.map { |row| row.fetch(:seat_numbers).max }.max,
      total_seats: rows.sum { |row| row.fetch(:seat_numbers).size },
      legend_json: section_specs.each_with_object({}) do |section, legend|
        legend[section.fetch(:code)] = {
          name: section.fetch(:name),
          color_hex: section[:color_hex],
          seat_type: section[:seat_type]
        }.compact
      end
    )
    layout.save!

    sections = sync_sections(layout, section_specs)
    section_map = sections.index_by(&:code)
    sync_seats(layout, section_map, rows: rows)
    layout
  end

  def upsert_show(screen:, layout:, movie:, language_code:, format_code:, start_time:, prices:)
    movie_language = movie.movie_languages.joins(:language).find_by!(languages: { code: language_code })
    movie_format = movie.movie_formats.joins(:format).find_by!(formats: { code: format_code })

    show = Show.find_or_initialize_by(
      screen: screen,
      movie: movie,
      start_time: start_time
    )
    show.assign_attributes(
      seat_layout: layout,
      movie_language: movie_language,
      movie_format: movie_format,
      end_time: start_time + movie.running_time.minutes,
      total_capacity: layout.total_seats,
      status: "scheduled"
    )
    show.save!

    prices.each do |section_code, amount|
      section = layout.seat_sections.find_by!(code: section_code)
      section_price = show.show_section_prices.find_or_initialize_by(seat_section: section)
      section_price.base_price = amount
      section_price.save!
    end

    show
  end

  bengaluru = City.find_or_create_by!(name: "Bengaluru", state: "Karnataka")
  hyderabad = City.find_or_create_by!(name: "Hyderabad", state: "Telangana")

  hindi = ensure_language!(code: "hi", name: "Hindi")
  english = ensure_language!(code: "en", name: "English")
  tamil = ensure_language!(code: "ta", name: "Tamil")

  format_2d = ensure_format!(code: "2d", name: "2D")
  format_3d = ensure_format!(code: "3d", name: "3D")
  format_imax = ensure_format!(code: "imax", name: "IMAX")

  vendor_one = upsert_user(
    email: "vendor.skyline@example.com",
    name: "Skyline Cinemas",
    phone: "+91 98765 10001",
    role: :vendor,
    password: "123456"
  )
  vendor_two = upsert_user(
    email: "vendor.harbor@example.com",
    name: "Harbor Screens",
    phone: "+91 98765 10002",
    role: :vendor,
    password: "123456"
  )

  viewer_one = upsert_user(
    email: "viewer.aisha@example.com",
    name: "Aisha Menon",
    phone: "+91 98765 20001",
    role: :user,
    password: "123456"
  )
  viewer_two = upsert_user(
    email: "viewer.rohan@example.com",
    name: "Rohan Iyer",
    phone: "+91 98765 20002",
    role: :user,
    password: "123456"
  )
  viewer_three = upsert_user(
    email: "viewer.neha@example.com",
    name: "Neha Kapoor",
    phone: "+91 98765 20003",
    role: :user,
    password: "123456"
  )

  theatre_one = Theatre.find_or_initialize_by(name: "Skyline Grand", city: bengaluru)
  theatre_one.assign_attributes(
    vendor: vendor_one,
    building_name: "Orion Avenue",
    street_address: "Rajajinagar Main Road",
    pincode: "560010"
  )
  theatre_one.save!

  theatre_two = Theatre.find_or_initialize_by(name: "Harbor Plex", city: hyderabad)
  theatre_two.assign_attributes(
    vendor: vendor_two,
    building_name: "Harbor Point Mall",
    street_address: "Madhapur High Street",
    pincode: "500081"
  )
  theatre_two.save!

  skyline_screen_one = Screen.find_or_initialize_by(theatre: theatre_one, name: "Audi 1")
  skyline_screen_one.assign_attributes(status: "active", total_rows: 6, total_columns: 8, total_seats: 48)
  skyline_screen_one.save!

  skyline_screen_two = Screen.find_or_initialize_by(theatre: theatre_one, name: "IMAX")
  skyline_screen_two.assign_attributes(status: "active", total_rows: 5, total_columns: 10, total_seats: 50)
  skyline_screen_two.save!

  harbor_screen_one = Screen.find_or_initialize_by(theatre: theatre_two, name: "Screen 2")
  harbor_screen_one.assign_attributes(status: "active", total_rows: 6, total_columns: 9, total_seats: 54)
  harbor_screen_one.save!

  [
    [ skyline_screen_one, format_2d ],
    [ skyline_screen_one, format_3d ],
    [ skyline_screen_two, format_2d ],
    [ skyline_screen_two, format_imax ],
    [ harbor_screen_one, format_2d ],
    [ harbor_screen_one, format_3d ]
  ].each do |screen, format|
    ScreenCapability.find_or_create_by!(screen: screen, format: format)
  end

  standard_sections = [
    { code: "silver", name: "Silver", rank: 0, color_hex: "#2563EB", seat_type: "standard" },
    { code: "gold", name: "Gold", rank: 1, color_hex: "#F59E0B", seat_type: "standard" }
  ]

  premium_sections = [
    { code: "prime", name: "Prime", rank: 0, color_hex: "#7C3AED", seat_type: "standard" },
    { code: "recliner", name: "Recliner", rank: 1, color_hex: "#DC2626", seat_type: "recliner" }
  ]

  skyline_layout_one = upsert_layout(
    screen: skyline_screen_one,
    name: "Standard Layout",
    section_specs: standard_sections,
    rows: [
      { row_label: "A", section_code: "silver", seat_numbers: (1..8).to_a },
      { row_label: "B", section_code: "silver", seat_numbers: (1..8).to_a },
      { row_label: "C", section_code: "silver", seat_numbers: (1..8).to_a },
      { row_label: "D", section_code: "gold", seat_numbers: (1..8).to_a },
      { row_label: "E", section_code: "gold", seat_numbers: (1..8).to_a, accessible_numbers: [ 1, 2 ] },
      { row_label: "F", section_code: "gold", seat_numbers: (1..8).to_a }
    ]
  )

  skyline_layout_two = upsert_layout(
    screen: skyline_screen_two,
    name: "IMAX Layout",
    section_specs: premium_sections,
    rows: [
      { row_label: "A", section_code: "prime", seat_numbers: (1..10).to_a },
      { row_label: "B", section_code: "prime", seat_numbers: (1..10).to_a },
      { row_label: "C", section_code: "prime", seat_numbers: (1..10).to_a },
      { row_label: "D", section_code: "recliner", seat_numbers: (1..10).to_a, seat_kind: "recliner" },
      { row_label: "E", section_code: "recliner", seat_numbers: (1..10).to_a, seat_kind: "recliner", accessible_numbers: [ 1 ] }
    ]
  )

  harbor_layout = upsert_layout(
    screen: harbor_screen_one,
    name: "Festival Layout",
    section_specs: standard_sections,
    rows: [
      { row_label: "A", section_code: "silver", seat_numbers: (1..9).to_a },
      { row_label: "B", section_code: "silver", seat_numbers: (1..9).to_a },
      { row_label: "C", section_code: "silver", seat_numbers: (1..9).to_a },
      { row_label: "D", section_code: "gold", seat_numbers: (1..9).to_a },
      { row_label: "E", section_code: "gold", seat_numbers: (1..9).to_a },
      { row_label: "F", section_code: "gold", seat_numbers: (1..9).to_a, accessible_numbers: [ 1, 2 ] }
    ]
  )

  movie_one = upsert_movie(
    {
      title: "Midnight Expressway",
      genre: "Action Thriller",
      rating: "UA",
      description: "An undercover courier gets trapped in a citywide chase after a routine midnight drop reveals a conspiracy inside the police network.",
      director: "Arjun Varma",
      running_time: 142,
      release_date: Date.new(2026, 3, 21)
    },
    language_specs: [
      { code: "en", name: "English", language_type: "original" },
      { code: "hi", name: "Hindi", language_type: "dubbed" }
    ],
    format_codes: %w[2d imax],
    cast_specs: [
      { name: "Ishaan Khattar", role: "actor", character_name: "Kabir" },
      { name: "Sobhita Dhulipala", role: "actor", character_name: "Mira" },
      { name: "Arjun Varma", role: "director" }
    ]
  )

  movie_two = upsert_movie(
    {
      title: "Monsoon Hearts",
      genre: "Romantic Drama",
      rating: "U",
      description: "Two architects reconnect during a storm-soaked restoration project and discover that rebuilding an old theatre may also restore their own unfinished story.",
      director: "Nila Raman",
      running_time: 128,
      release_date: Date.new(2026, 3, 28)
    },
    language_specs: [
      { code: "hi", name: "Hindi", language_type: "original" },
      { code: "ta", name: "Tamil", language_type: "dubbed" }
    ],
    format_codes: %w[2d],
    cast_specs: [
      { name: "Mrunal Thakur", role: "actor", character_name: "Anika" },
      { name: "Dulquer Salmaan", role: "actor", character_name: "Reyansh" },
      { name: "Nila Raman", role: "director" }
    ]
  )

  movie_three = upsert_movie(
    {
      title: "Pixel Planet",
      genre: "Animation Adventure",
      rating: "U",
      description: "A young gamer and a rogue repair bot dive into a glitching virtual world to save thousands of stranded players before the final server reset.",
      director: "Karthik Dev",
      running_time: 114,
      release_date: Date.new(2026, 4, 2)
    },
    language_specs: [
      { code: "en", name: "English", language_type: "original" },
      { code: "hi", name: "Hindi", language_type: "dubbed" },
      { code: "ta", name: "Tamil", language_type: "dubbed" }
    ],
    format_codes: %w[2d 3d],
    cast_specs: [
      { name: "Ritwik Bhowmik", role: "actor", character_name: "Ari" },
      { name: "Mithila Palkar", role: "actor", character_name: "Nova" },
      { name: "Karthik Dev", role: "director" }
    ]
  )

  review_specs = [
    [ viewer_one, movie_one, 4.5, "Tense, stylish, and packed with momentum. The night chase sequences are easily the best part." ],
    [ viewer_two, movie_two, 4.0, "Warm performances and a very easy watch. The theatre backdrop gives the romance a nice personality." ],
    [ viewer_three, movie_three, 4.5, "Colorful, funny, and surprisingly emotional. This one works for both kids and adults." ]
  ]

  review_specs.each do |user, movie, rating, description|
    review = Review.find_or_initialize_by(user: user, movie: movie)
    review.assign_attributes(
      rating: rating,
      description: description,
      reviewed_on: Date.current
    )
    review.save!
  end

  tomorrow = Time.zone.tomorrow.beginning_of_day

  show_plan = [
    [ skyline_screen_one, skyline_layout_one, movie_two, "hi", "2d", tomorrow + 11.hours, { "silver" => 180, "gold" => 260 } ],
    [ skyline_screen_one, skyline_layout_one, movie_three, "en", "2d", tomorrow + 15.hours, { "silver" => 200, "gold" => 280 } ],
    [ skyline_screen_two, skyline_layout_two, movie_one, "en", "imax", tomorrow + 19.hours, { "prime" => 390, "recliner" => 620 } ],
    [ harbor_screen_one, harbor_layout, movie_three, "hi", "3d", tomorrow + 12.hours, { "silver" => 210, "gold" => 290 } ],
    [ harbor_screen_one, harbor_layout, movie_two, "ta", "2d", tomorrow + 16.hours, { "silver" => 170, "gold" => 240 } ],
    [ skyline_screen_one, skyline_layout_one, movie_one, "hi", "2d", tomorrow + 1.day + 13.hours, { "silver" => 220, "gold" => 310 } ],
    [ skyline_screen_two, skyline_layout_two, movie_three, "en", "2d", tomorrow + 1.day + 18.hours, { "prime" => 260, "recliner" => 420 } ],
    [ harbor_screen_one, harbor_layout, movie_one, "hi", "2d", tomorrow + 2.days + 20.hours, { "silver" => 230, "gold" => 320 } ]
  ]

  show_plan.each do |screen, layout, movie, language_code, format_code, start_time, prices|
    upsert_show(
      screen: screen,
      layout: layout,
      movie: movie,
      language_code: language_code,
      format_code: format_code,
      start_time: start_time,
      prices: prices
    )
  end
end

puts "Seed data created successfully without creating any admin accounts."
