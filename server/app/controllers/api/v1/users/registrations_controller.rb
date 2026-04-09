module Api::V1::Users
  class RegistrationsController < Api::V1::BaseRegistrationsController
    private
    def operation_class = ::Users::Register
  end
end
