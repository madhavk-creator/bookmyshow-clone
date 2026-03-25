# Admin accounts should only be created by existing admins.
# The controller enforces this via Pundit before calling this operation.
module Admin
  class Register < User::Register
    private

    def assign_role(ctx, model:, **)
      model.role = :admin
    end
  end
end