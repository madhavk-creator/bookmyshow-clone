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
  end
end
