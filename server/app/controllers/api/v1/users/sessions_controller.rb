# app/controllers/api/v1/users/sessions_controller.rb
module Api::V1::Users
  class SessionsController < Api::V1::BaseSessionsController
    private
    def expected_role = :user
  end
end

# app/controllers/api/v1/vendors/sessions_controller.rb
module Api::V1::Vendors
  class SessionsController < Api::V1::BaseSessionsController
    private
    def expected_role = :vendor
  end
end

# app/controllers/api/v1/admin/sessions_controller.rb
module Api::V1::Admin
  class SessionsController < Api::V1::BaseSessionsController
    private
    def expected_role = :admin
  end
end