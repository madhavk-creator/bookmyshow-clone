module Api::V1::Admin
  class SessionsController < Api::V1::BaseSessionsController
    private
    def expected_role = :admin
  end
end
