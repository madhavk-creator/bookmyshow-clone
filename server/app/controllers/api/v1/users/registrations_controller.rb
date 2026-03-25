# app/controllers/api/v1/users/registrations_controller.rb
module Api::V1::Users
  class RegistrationsController < Api::V1::BaseRegistrationsController
    private
    def operation_class = User::Register
  end
end

# app/controllers/api/v1/vendors/registrations_controller.rb
module Api::V1::Vendors
  class RegistrationsController < Api::V1::BaseRegistrationsController
    private
    def operation_class = Vendor::Register
  end
end

# app/controllers/api/v1/admin/registrations_controller.rb
module Api::V1::Admin
  class RegistrationsController < Api::V1::BaseRegistrationsController
    #admin registration requires an existing admin
    before_action :authenticate!
    before_action :require_admin!

    private

    def operation_class = Admin::Register

    def require_admin!
      render json: { error: 'Forbidden' }, status: :forbidden unless current_user&.admin?
    end
  end
end