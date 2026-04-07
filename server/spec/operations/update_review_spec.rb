require "rails_helper"

RSpec.describe Reviews::Update do
  let(:user) { create(:user, name: "Reviewer") }
  let(:movie) { create(:movie, title: "Reviewable Movie", description: "A long enough description for validation", running_time: 110, release_date: "2024-01-01") }
  let(:review) { create(:review, user: user, movie: movie, description: "This movie was surprisingly thoughtful and well made.", rating: 4.0, reviewed_on: Date.current) }

  it "updates a user's own review" do
    result = Reviews::Update.call(
      current_user: user,
      params: {
        id: review.id,
        movie_id: movie.id,
        description: "Updated review text that still satisfies validation.",
        rating: 5.0
      }
    )

    expect(result).to be_success
    expect(result[:model].description).to eq("Updated review text that still satisfies validation.")
    expect(result[:model].rating).to eq(5.0)
  end
end
