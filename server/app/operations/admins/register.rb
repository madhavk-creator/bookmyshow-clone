# Admin accounts should only be created by existing admins.
module Admins
  class Register < Users::Register
    def assign_role(ctx, model:, current_user:, **)
      unless current_user&.admin?
        ctx[:errors] = { base: [ "Not authorized to create admin users" ] }
        return false
      end

      model.role = :admin
    end
  end
end
