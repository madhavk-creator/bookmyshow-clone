FactoryBot.define do
  factory :language do
    sequence(:name) { |n| "English #{n}" }
    sequence(:code) do |n|
      index = n - 1
      first = (index / 26) % 26
      second = index % 26
      "#{(97 + first).chr}#{(97 + second).chr}"
    end
  end

  factory :format do
    sequence(:name) { |n| "IMAX#{n}" }
    sequence(:code) { |n| "imax#{n}" }
  end

  factory :movie do
    sequence(:title) { |n| "Movie #{n}" }
    genre { "Drama" }
    rating { :ua }
    description { "A sufficiently descriptive movie summary for tests." }
    director { "Director Name" }
    running_time { 120 }
    release_date { Date.new(2026, 4, 1) }
  end

  factory :cast_member do
    movie
    sequence(:name) { |n| "Cast Member #{n}" }
    role { :actor }
    character_name { "Lead" }
  end

  factory :movie_language do
    movie
    language
    language_type { :original }
  end

  factory :movie_format do
    movie
    format
  end

  factory :screen_capability do
    screen
    format
  end

  factory :review do
    user
    movie
    rating { 4.5 }
    description { "This was a very engaging movie with a strong second half." }
    reviewed_on { Date.current }
  end
end
