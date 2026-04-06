require 'rails_helper'

RSpec.describe Users::Register do
  context "with valid parameters" do
    it "creates a user" do
      params = {
        name: "vendor",
        email: "v@example.com",
        phone: "1234567090",
        password: "password123",
        password_confirmation: "password123"
      }

      result = Users::Register.call(params: params)
      expect(result).to be_success
      user = result[:model]
      expect(user.name).to eq("vendor")
      expect(user.email).to eq("v@example.com")
    end
  end
end
