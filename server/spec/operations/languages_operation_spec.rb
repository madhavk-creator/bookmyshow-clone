require "rails_helper"

RSpec.describe "Languages operations auth and lookup" do
  describe Languages::Create do
    it "forbids regular users from creating a language" do
      result = Languages::Create.call(
        current_user: create(:user),
        params: { name: "Hindi", code: "hi" }
      )

      expect(result).not_to be_success
      expect(result[:errors][:base]).to include("Not authorized to create language")
    end
  end

  describe Languages::Update do
    it "returns not found for unknown language id" do
      result = Languages::Update.call(
        current_user: create(:user, :admin),
        params: { id: SecureRandom.uuid, name: "Tamil", code: "ta" }
      )

      expect(result).not_to be_success
      expect(result[:errors][:base]).to include("Language not found")
    end
  end

  describe Languages::Destroy do
    it "forbids regular users from deleting a language" do
      language = create(:language)
      result = Languages::Destroy.call(
        current_user: create(:user),
        params: { id: language.id }
      )

      expect(result).not_to be_success
      expect(result[:errors][:base]).to include("Not authorized to delete this language")
    end

    it "blocks deleting a language that still has scheduled shows" do
      admin = create(:user, :admin)
      language = create(:language, code: "hi")
      vendor = create(:user, :vendor)
      theatre = create(:theatre, vendor: vendor)
      screen = create(:screen, theatre: theatre)
      format = create(:format)
      create(:screen_capability, screen: screen, format: format)
      movie = create(:movie)
      movie_language = create(:movie_language, movie: movie, language: language)
      movie_format = create(:movie_format, movie: movie, format: format)
      layout = create(:seat_layout, :published, screen: screen)
      create(
        :show,
        screen: screen,
        seat_layout: layout,
        movie: movie,
        movie_language: movie_language,
        movie_format: movie_format,
        status: :scheduled
      )

      result = Languages::Destroy.call(
        current_user: admin,
        params: { id: language.id }
      )

      expect(result).not_to be_success
      expect(result[:errors][:base]).to include("Cannot delete a language that still has scheduled shows")
    end
  end
end
