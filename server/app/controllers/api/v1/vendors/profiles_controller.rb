module Api::V1::Vendors
  class ProfilesController < Api::V1::BaseProfilesController
    private

    def expected_role = :vendor
  end
end
