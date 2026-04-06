module Api
  module V1
    class BaseProfilesController < ApplicationController
      before_action :authenticate!
      before_action :ensure_expected_role!

      def update
        authorize current_user, :update?

        if current_user.update(profile_params)
          render json: success_payload(current_user)
        else
          render json: { errors: current_user.errors.to_hash(true) }, status: :unprocessable_entity
        end
      end

      def update_password
        authorize current_user, :update?

        unless password_payload[:current_password].present?
          return render json: { errors: { current_password: [ "can't be blank" ] } }, status: :unprocessable_entity
        end

        unless current_user.valid_password?(password_payload[:current_password])
          return render json: { errors: { current_password: [ "is incorrect" ] } }, status: :unprocessable_entity
        end

        if current_user.update(password_update_params)
          render json: success_payload(current_user)
        else
          render json: { errors: current_user.errors.to_hash(true) }, status: :unprocessable_entity
        end
      end

      private

      def expected_role = raise(NotImplementedError)

      def ensure_expected_role!
        return if current_user&.role == expected_role.to_s

        render json: { error: "Forbidden" }, status: :forbidden
      end

      def profile_params = profile_payload.permit(:name, :email, :phone)

      def password_update_params = password_payload.permit(:password, :password_confirmation)

      def profile_payload = extract_payload(:profile, :user, :vendor)

      def password_payload = extract_payload(:password, :user, :vendor)

      def extract_payload(*keys)
        payload = keys.lazy.map { |key| params[key] }.find(&:present?) || params
        payload.is_a?(ActionController::Parameters) ? payload : ActionController::Parameters.new(payload)
      end

      def success_payload(user)
        {
          token: JsonWebToken.encode({ user_id: user.id }),
          user: serialize(user)
        }
      end

      def serialize(user) = { id: user.id, name: user.name, email: user.email, phone: user.phone, role: user.role }
    end
  end
end
