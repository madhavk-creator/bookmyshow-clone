require "test_helper"

class ProfileUpdatesTest < ActionDispatch::IntegrationTest
  test "user can update profile details and receives a fresh token" do
    user = User.create!(
      name: "Profile User",
      email: "profile-user@example.com",
      password: "password",
      password_confirmation: "password",
      role: :user,
      phone: "9999999999",
      is_active: true
    )

    patch "/api/v1/users/profile",
          params: {
            profile: {
              name: "Updated User",
              phone: "+91 98765 43210"
            }
          },
          headers: { "Authorization" => "Bearer #{token_for(user)}" },
          as: :json

    assert_response :success

    user.reload
    assert_equal "Updated User", user.name
    assert_equal "+91 98765 43210", user.phone
    assert_equal user.id, response.parsed_body.dig("user", "id")
    assert response.parsed_body["token"].present?
  end

  test "vendor can update password and use the refreshed token" do
    vendor = User.create!(
      name: "Vendor Profile",
      email: "vendor-profile@example.com",
      password: "password",
      password_confirmation: "password",
      role: :vendor,
      is_active: true
    )

    patch "/api/v1/vendors/password",
          params: {
            password: {
              current_password: "password",
              password: "new-password",
              password_confirmation: "new-password"
            }
          },
          headers: { "Authorization" => "Bearer #{token_for(vendor)}" },
          as: :json

    assert_response :success

    vendor.reload
    assert vendor.valid_password?("new-password")

    fresh_token = response.parsed_body["token"]

    patch "/api/v1/vendors/profile",
          params: { profile: { name: "Vendor Updated" } },
          headers: { "Authorization" => "Bearer #{fresh_token}" },
          as: :json

    assert_response :success
    assert_equal "Vendor Updated", response.parsed_body.dig("user", "name")
  end

  test "wrong current password returns validation errors" do
    user = User.create!(
      name: "Password User",
      email: "password-user@example.com",
      password: "password",
      password_confirmation: "password",
      role: :user,
      is_active: true
    )

    patch "/api/v1/users/password",
          params: {
            password: {
              current_password: "wrong-password",
              password: "new-password",
              password_confirmation: "new-password"
            }
          },
          headers: { "Authorization" => "Bearer #{token_for(user)}" },
          as: :json

    assert_response :unprocessable_entity
    assert_equal [ "is incorrect" ], response.parsed_body.dig("errors", "current_password")
  end

  private

  def token_for(user)
    JsonWebToken.encode(user_id: user.id)
  end
end
