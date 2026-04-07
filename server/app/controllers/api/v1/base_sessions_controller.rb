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
        result = run Users::Login, params: login_params, expected_role: expected_role do |operation_result|
          return render json: operation_result[:response_data], status: :ok
        end

        render json: { error: result[:error] }, status: (result[:status] || :unprocessable_entity)
      end

      private

      def expected_role = raise(NotImplementedError)

      def login_params = params.permit(:email, :password).to_h.deep_symbolize_keys
    end
  end
end
