require "rails_helper"

RSpec.describe "Cities operations auth and lookup" do
  describe Cities::Create do
    it "forbids regular users from creating a city" do
      result = Cities::Create.call(
        current_user: create(:user),
        params: { name: "Pune", state: "Maharashtra" }
      )

      expect(result).not_to be_success
      expect(result[:errors][:base]).to include("Not authorized to create city")
    end
  end

  describe Cities::Update do
    it "returns not found for unknown city id" do
      result = Cities::Update.call(
        current_user: create(:user, :admin),
        params: { id: SecureRandom.uuid, name: "Updated City", state: "Karnataka" }
      )

      expect(result).not_to be_success
      expect(result[:errors][:base]).to include("City not found")
    end
  end

  describe Cities::Destroy do
    it "forbids vendors from deleting a city" do
      city = create(:city)
      result = Cities::Destroy.call(
        current_user: create(:user, :vendor),
        params: { id: city.id }
      )

      expect(result).not_to be_success
      expect(result[:errors][:base]).to include("Not authorized to delete this city")
    end
  end
end
