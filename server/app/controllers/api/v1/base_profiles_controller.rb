module Api
  module V1
    class BaseProfilesController < ApplicationController
      before_action :authenticate!

      def update
        result = run Users::UpdateProfile, params: profile_params, expected_role: expected_role do |operation_result|
          return render json: operation_result[:response_data], status: :ok
        end

        render json: { errors: result[:errors] }, status: (result[:status] || :unprocessable_entity)
      end

      def update_password
        result = run Users::UpdatePassword, params: password_update_params, expected_role: expected_role do |operation_result|
          return render json: operation_result[:response_data], status: :ok
        end

        render json: { errors: result[:errors] }, status: (result[:status] || :unprocessable_entity)
      end

      private

      def expected_role = raise(NotImplementedError)

      def password_update_params = password_payload.permit(:current_password, :password, :password_confirmation).to_h.deep_symbolize_keys

      def profile_payload = extract_payload(:profile, :user, :vendor, :admin)

      def password_payload = extract_payload(:password, :user, :vendor, :admin)

      def extract_payload(*keys)
        payload = keys.lazy.map { |key| params[key] }.find(&:present?) || params
        payload.is_a?(ActionController::Parameters) ? payload : ActionController::Parameters.new(payload)
      end

      def profile_params
        profile_payload.permit(:name, :email, :phone).to_h.deep_symbolize_keys
      end
    end
  end
end
