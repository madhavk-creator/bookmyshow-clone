# Login flow:
#   1. Find users by email
#   2. Verify password via Devise's valid_password?
#   3. Check is_active and role
#   4. Mint JWT via JsonWebToken.encode
#   5. Return token in response body
#
# Logout is client-side — the client discards the token.
# Server-side invalidation is not implemented.

module Api
  module V1
    class BaseSessionsController < ApplicationController
      skip_before_action :authenticate!, raise: false

      # POST /api/v1/(users|vendors|admins)/login
      def create
        user = User.find_by(email: email_param)

        unless user&.valid_password?(password_param)
          render json: { error: "Invalid email or password" }, status: :unauthorized and return
        end

        unless user.is_active?
          render json: { error: "Account is deactivated. Contact support." },
                 status: :unauthorized and return
        end

        unless user.role == expected_role.to_s
          render json: { error: "Invalid email or password" }, status: :unauthorized and return
        end

        token = JsonWebToken.encode({ user_id: user.id })

        render json: {
          token: token,
          user:  serialize(user)
        }, status: :ok
      end

      private

      def expected_role = raise(NotImplementedError)

      def login_payload = params

      def email_param = login_payload[:email]&.downcase&.strip

      def password_param = login_payload[:password]

      def serialize(user) = { id: user.id, name: user.name, email: user.email, phone: user.phone, role: user.role }
    end
  end
end
