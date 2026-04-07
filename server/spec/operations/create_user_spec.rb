require "rails_helper"

RSpec.describe Users::Register do
  it "creates a user with valid parameters" do
    params = attributes_for(
      :user,
      name: "Vendor",
      email: "v@example.com",
      phone: "1234567090",
      password: "password123",
      password_confirmation: "password123"
    ).slice(:name, :email, :phone, :password, :password_confirmation)

    result = Users::Register.call(params: params)

    expect(result).to be_success
    user = result[:model]
    expect(user.name).to eq("Vendor")
    expect(user.email).to eq("v@example.com")
    expect(user).to be_user
  end

  it "returns an error when the password confirmation does not match" do
    params = attributes_for(
      :user,
      password: "password123",
      password_confirmation: "different123"
    ).slice(:name, :email, :phone, :password, :password_confirmation)

    result = Users::Register.call(params: params)

    expect(result).not_to be_success
    expect(result[:errors]).to have_key(:password_confirmation)
  end

  it "returns an error when the email is already taken" do
    create(:user, email: "v@example.com")
    params = attributes_for(
      :user,
      email: "v@example.com"
    ).slice(:name, :email, :phone, :password, :password_confirmation)

    result = Users::Register.call(params: params)

    expect(result).not_to be_success
    expect(result[:errors]).to have_key(:email)
  end

  it "returns an error when required fields are missing" do
    result = Users::Register.call(
      params: {
        email: "missing-name@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    )

    expect(result).not_to be_success
    expect(result[:errors]).to have_key(:base)
    expect(result[:errors][:base].first).to include("Missing required fields")
    expect(result[:errors][:base].first).to include("name")
  end
end
