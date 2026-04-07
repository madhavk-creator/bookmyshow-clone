require "rails_helper"

RSpec.describe Movies::Update do
  let(:movie) { create(:movie, title: "Original Title", description: "Original Description", director: "Original Director", running_time: 100, release_date: "2023-01-01") }
  let(:admin) { create(:user, :admin) }

  context "with valid parameters" do
    it "updates the movie and its associations" do
      spanish = create(:language, name: "Spanish", code: "es")
      german = create(:language, name: "German", code: "de")
      imax = create(:format, name: "IMAX", code: "imax")
      four_dx = create(:format, name: "4DX", code: "4dx")

      params = {
        title: "Updated Title",
        genre: "Updated Genre",
        rating: "A",
        description: "Updated Description",
        director: "Updated Director",
        running_time: 120,
        release_date: "2024-01-01",
        language_entries: [
          { language_id: spanish.id, type: "original" },
          { language_id: german.id, type: "dubbed" }
        ],
        format_ids: [
          imax.id,
          four_dx.id
        ],
        cast_members: [
          attributes_for(:cast_member, name: "Updated Actor", role: "actor", character_name: "Updated Character").slice(:name, :role, :character_name),
          attributes_for(:cast_member, name: "Updated Director", role: "director", character_name: nil).slice(:name, :role, :character_name)
        ]
      }

      result = Movies::Update.call(current_user: admin, model: movie, params: params)

      expect(result).to be_success
      updated_movie = result[:model]
      expect(updated_movie.title).to eq("Updated Title")
      expect(updated_movie.genre).to eq("Updated Genre")
      expect(updated_movie.rating).to eq("a")
      expect(updated_movie.description).to eq("Updated Description")
      expect(updated_movie.director).to eq("Updated Director")
      expect(updated_movie.running_time).to eq(120)
      expect(updated_movie.release_date.to_s).to eq("2024-01-01")
      expect(updated_movie.movie_languages.count).to eq(2)
      expect(updated_movie.movie_formats.count).to eq(2)
      expect(updated_movie.cast_members.count).to eq(2)
    end
  end
end
