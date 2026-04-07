FactoryBot.define do
  factory :seat_layout do
    screen
    sequence(:name) { |n| "Layout #{n}" }
    total_rows { screen.total_rows }
    total_columns { screen.total_columns }
    total_seats { screen.total_seats }
    status { :draft }
    legend_json { {} }
    screen_label { screen.name }

    trait :published do
      status { :published }
      published_at { Time.current }
    end
  end

  factory :seat_section do
    seat_layout
    sequence(:code) { |n| "section_#{n}" }
    sequence(:name) { |n| "Section #{n}" }
    color_hex { "#FFAA00" }
    sequence(:rank) { |n| n }
  end

  factory :seat do
    transient do
      seat_sequence { 1 }
    end

    seat_layout
    seat_section { association :seat_section, seat_layout: seat_layout }
    row_label { "A" }
    seat_number { seat_sequence }
    grid_row { 1 }
    grid_column { seat_sequence }
    seat_kind { :standard }
    is_accessible { false }
    is_active { true }
    x_span { 1 }
    y_span { 1 }
  end

  factory :show do
    transient do
      show_start_time { 2.days.from_now.change(min: 0) }
      seat_count { 3 }
    end

    screen do
      association :screen,
                  total_rows: 5,
                  total_columns: 5,
                  total_seats: seat_count
    end
    seat_layout do
      association :seat_layout,
                  :published,
                  screen: screen,
                  total_rows: screen.total_rows,
                  total_columns: screen.total_columns,
                  total_seats: seat_count
    end
    movie
    movie_language { association :movie_language, movie: movie }
    movie_format { association :movie_format, movie: movie }
    start_time { show_start_time }
    end_time { start_time + movie.running_time.minutes }
    total_capacity { seat_count }
    status { :scheduled }

    before(:create) do |show|
      ScreenCapability.find_or_create_by!(screen: show.screen, format: show.movie_format.format)
    end

    trait :bookable do
      transient do
        base_price { 100 }
      end

      after(:create) do |show, evaluator|
        section = show.seat_layout.seat_sections.first || create(
          :seat_section,
          seat_layout: show.seat_layout,
          code: "prime",
          name: "Prime",
          rank: 1
        )

        create(
          :show_section_price,
          show: show,
          seat_section: section,
          base_price: evaluator.base_price
        )

        next if show.seat_layout.seats.exists?

        evaluator.seat_count.times do |index|
          create(
            :seat,
            seat_layout: show.seat_layout,
            seat_section: section,
            seat_sequence: index + 1
          )
        end
      end
    end
  end

  factory :show_section_price do
    show
    seat_section do
      show.seat_layout.seat_sections.first || association(:seat_section, seat_layout: show.seat_layout)
    end
    base_price { 100 }
  end

  factory :show_seat_state do
    transient do
      locked_user { nil }
    end

    show
    seat do
      section = show.seat_layout.seat_sections.first || create(:seat_section, seat_layout: show.seat_layout)
      association :seat, seat_layout: show.seat_layout, seat_section: section
    end
    status { :locked }
    locked_by_user { locked_user || association(:user) }
    lock_token { SecureRandom.uuid }
    locked_until { 5.minutes.from_now }

    trait :booked do
      status { :booked }
      locked_by_user { nil }
      lock_token { nil }
      locked_until { nil }
    end

    trait :blocked do
      status { :blocked }
      locked_by_user { nil }
      lock_token { nil }
      locked_until { nil }
    end
  end
end
