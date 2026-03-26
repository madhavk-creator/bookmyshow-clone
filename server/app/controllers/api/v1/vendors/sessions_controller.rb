module Api::V1::Vendors
  class SessionsController < Api::V1::BaseSessionsController
    private
    def expected_role = :vendor
  end
end