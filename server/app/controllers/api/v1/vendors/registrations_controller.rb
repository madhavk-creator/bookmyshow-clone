module Api::V1::Vendors
  class RegistrationsController < Api::V1::BaseRegistrationsController
    private
    def operation_class = Vendors::Register
  end
end
