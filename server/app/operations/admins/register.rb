# Admin accounts should only be created by existing admins.
# The controller enforces this via Pundit before calling this operation.
module Admins
  class Register < Users::Register
    def assign_role(ctx, model:, **)
      model.role = :admin
    end
  end
end
