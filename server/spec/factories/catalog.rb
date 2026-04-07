FactoryBot.define do
  factory :language do
    sequence(:name) { |n| "English #{n}" }
    sequence(:code) do |n|
      suffix = (n - 1).to_s(26).tr("0-9a-p", "a-q")
      "en#{suffix}"
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
