module Api::V1::Admin
  class RegistrationsController < Api::V1::BaseRegistrationsController
    # admins registration requires an existing admins
    before_action :authenticate!
    before_action :require_admin!

    private

    def operation_class = Admins::Register

    def require_admin!
      render json: { error: "Forbidden" }, status: :forbidden unless current_user&.admin?
    end
  end
end
