module Api::V1::Admin
  class RegistrationsController < Api::V1::BaseRegistrationsController
    # admins registration requires an existing admins
    before_action :authenticate!

    private

    def operation_class = ::Admins::Register
  end
end
