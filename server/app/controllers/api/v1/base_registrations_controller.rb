module Api
  module V1
    class BaseRegistrationsController < ApplicationController
      skip_before_action :authenticate!, raise: false

      # POST /api/v1/(users|vendors|admins)/register
      def create
        result = run(operation_class, params: registration_params.to_h) do |operation_result|
          token = JsonWebToken.encode({ user_id: operation_result[:model].id })
          return render json: { token: token, user: serialize(operation_result[:model]) }, status: :created
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
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
