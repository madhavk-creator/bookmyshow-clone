require "rails_helper"

RSpec.describe Movies::Create do
  context "with valid parameters" do
    it "creates a movie with associated languages, formats, and cast members" do
      params = {
        title: "Inception",
        genre: "Sci-Fi",
        rating: "UA",
        description: "A mind-bending thriller",
        director: "Christopher Nolan",
        running_time: 148,
        release_date: "2010-07-16",
        language_entries: [
          { language_id: Language.create!(name: "English", code: "en").id, type: "original" },
          { language_id: Language.create!(name: "French", code: "fr").id, type: "dubbed" }
        ],
        format_ids: [
          Format.create!(name: "2D", code: "2d").id,
          Format.create!(name: "3D", code: "3d").id
        ],
        cast_members: [
          { name: "Leonardo DiCaprio", role: "actor", character_name: "Cobb" },
          { name: "Christopher Nolan", role: "director" }
        ]
      }

      result = Movies::Create.call(params: params)

      expect(result).to be_success
      movie = result[:model]
      expect(movie.title).to eq("Inception")
      expect(movie.movie_languages.count).to eq(2)
      expect(movie.movie_formats.count).to eq(2)
      expect(movie.cast_members.count).to eq(2)
    end
  end
end
