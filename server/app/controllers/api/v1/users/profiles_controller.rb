module Api::V1::Users
  class ProfilesController < Api::V1::BaseProfilesController
    private

    def expected_role = :user
  end
end
