require "rails_helper"

RSpec.describe "Formats operations auth and lookup" do
  describe Formats::Create do
    it "forbids regular users from creating a format" do
      result = Formats::Create.call(
        current_user: create(:user),
        params: { name: "IMAX", code: "imax" }
      )

      expect(result).not_to be_success
      expect(result[:errors][:base]).to include("Not authorized to create format")
    end
  end

  describe Formats::Update do
    it "allows vendors to update format attributes" do
      format = create(:format, name: "TwoD", code: "2d")
      result = Formats::Update.call(
        current_user: create(:user, :vendor),
        params: { id: format.id, name: "THREED", code: "3d" }
      )

      expect(result).to be_success
      expect(result[:model].reload.name).to eq("THREED")
      expect(result[:model].code).to eq("3d")
    end
  end

  describe Formats::Destroy do
    it "returns not found for unknown format id" do
      result = Formats::Destroy.call(
        current_user: create(:user, :admin),
        params: { id: SecureRandom.uuid }
      )

      expect(result).not_to be_success
      expect(result[:errors][:base]).to include("Format not found")
    end

    it "blocks deleting a format that still has scheduled shows" do
      admin = create(:user, :admin)
      format = create(:format, code: "imax")
      vendor = create(:user, :vendor)
      theatre = create(:theatre, vendor: vendor)
      screen = create(:screen, theatre: theatre)
      create(:screen_capability, screen: screen, format: format)
      movie = create(:movie)
      movie_language = create(:movie_language, movie: movie)
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

      result = Formats::Destroy.call(
        current_user: admin,
        params: { id: format.id }
      )

      expect(result).not_to be_success
      expect(result[:errors][:base]).to include("Cannot delete a format that is still enabled on screens")
    end
  end
end
