require "rails_helper"

RSpec.describe Movies::Create do
  context "with valid parameters" do
    it "creates a movie with associated languages, formats, and cast members" do
      english = create(:language, name: "English", code: "en")
      french = create(:language, name: "French", code: "fr")
      two_d = create(:format, name: "2D", code: "2d")
      three_d = create(:format, name: "3D", code: "3d")

      params = {
        title: "Inception",
        genre: "Sci-Fi",
        rating: "UA",
        description: "A mind-bending thriller",
        director: "Christopher Nolan",
        running_time: 148,
        release_date: "2010-07-16",
        language_entries: [
          { language_id: english.id, type: "original" },
          { language_id: french.id, type: "dubbed" }
        ],
        format_ids: [ two_d.id, three_d.id ],
        cast_members: [
          attributes_for(:cast_member, name: "Leonardo DiCaprio", role: "actor", character_name: "Cobb").slice(:name, :role, :character_name),
          attributes_for(:cast_member, name: "Christopher Nolan", role: "director", character_name: nil).slice(:name, :role, :character_name)
        ]
      }

      result = Movies::Create.call(params: params)

      expect(result).to be_success
      movie = result[:model]
      expect(movie.title).to eq("Inception")
      expect(movie.movie_languages.count).to eq(2)
      expect(movie.movie_formats.count).to eq(2)
      expect(movie.cast_members.count).to eq(2)
      expect(movie.cast_members.pluck(:name)).to include("Leonardo DiCaprio", "Christopher Nolan")
    end
  end
end
