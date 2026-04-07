require "test_helper"

class AuthFlowTest < ActionDispatch::IntegrationTest
  test "users login returns a token with only user_id based identity claims" do
    user = User.create!(
      name: "Test User",
      email: "users@example.com",
      password: "password",
      password_confirmation: "password",
      role: :user,
      is_active: true
    )

    post "/api/v1/users/login",
         params: {
           user: {
             email: user.email,
             password: "password"
           }
         },
         as: :json

    assert_response :success

    payload = JsonWebToken.decode(response.parsed_body["token"])

    assert_equal user.id, payload[:user_id]
    assert_nil payload[:role]
  end

  test "vendors cannot log in through the users endpoint" do
    vendor = User.create!(
      name: "Vendor User",
      email: "vendors@example.com",
      password: "password",
      password_confirmation: "password",
      role: :vendor,
      is_active: true
    )

    post "/api/v1/users/login",
         params: {
           user: {
             email: vendor.email,
             password: "password"
           }
         },
         as: :json

    assert_response :unauthorized
  end

  test "login with root-level fields works" do
    user = User.create!(
      name: "Root User",
      email: "root@example.com",
      password: "password",
      password_confirmation: "password",
      role: :user,
      is_active: true
    )

    post "/api/v1/users/login",
         params: {
           email: user.email,
           password: "password"
         },
         as: :json

    assert_response :success

    payload = JsonWebToken.decode(response.parsed_body["token"])
    assert_equal user.id, payload[:user_id]
  end
end
