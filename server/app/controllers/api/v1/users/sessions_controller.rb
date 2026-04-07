module Api::V1::Users
  class SessionsController < Api::V1::BaseSessionsController
    private
    def expected_role = :user
  end
end
