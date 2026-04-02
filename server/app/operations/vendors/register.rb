module Vendor
  class Register < User::Register
    private

    def assign_role(ctx, model:, **)
      model.role = :vendor
    end
  end
end