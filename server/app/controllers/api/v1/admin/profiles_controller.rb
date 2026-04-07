module Api::V1::Admin
  class ProfilesController < Api::V1::BaseProfilesController
    private

    def expected_role = :admin
  end
end
