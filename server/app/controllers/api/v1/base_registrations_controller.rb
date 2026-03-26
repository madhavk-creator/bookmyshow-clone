module Api
  module V1
    class BaseRegistrationsController < ApplicationController
      skip_before_action :authenticate!, raise: false

      # POST /api/v1/(users|vendors|admin)/register
      def create
        result = operation_class.call(params: registration_params.to_h)

        if result.success?
          token = JsonWebToken.encode({ user_id: result[:model].id })
          render json: { token: token, user: serialize(result[:model]) }, status: :created
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      private

      def operation_class
        raise NotImplementedError
      end

      def registration_params
        params.require(:registration).permit(:name, :email, :password, :password_confirmation, :phone)
      end

      def serialize(user)
        { id: user.id, name: user.name, email: user.email, phone: user.phone, role: user.role }
      end
    end
  end
end
