require "rails_helper"

RSpec.describe Reviews::Update do
  let(:user) do
    User.create!(
      name: "Reviewer",
      email: "reviewer-#{SecureRandom.hex(4)}@example.com",
      password: "password",
      password_confirmation: "password",
      phone: "9876543210",
      role: :user,
      is_active: true
    )
  end

  let(:movie) do
    Movie.create!(
      title: "Reviewable Movie",
      genre: "Drama",
      rating: "UA",
      description: "A long enough description for validation",
      director: "Director Name",
      running_time: 110,
      release_date: "2024-01-01"
    )
  end

  let(:review) do
    Review.create!(
      user: user,
      movie: movie,
      description: "This movie was surprisingly thoughtful and well made.",
      rating: 4.0,
      reviewed_on: Date.current
    )
  end

  it "updates a user's own review" do
    result = Reviews::Update.call(
      current_user: user,
      params: {
        id: review.id,
        description: "Updated review text that still satisfies validation.",
        rating: 5.0
      }
    )

    expect(result).to be_success
    expect(result[:model].description).to eq("Updated review text that still satisfies validation.")
    expect(result[:model].rating).to eq(5.0)
  end
end
