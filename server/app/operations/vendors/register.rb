module Vendors
  class Register < Users::Register
    def assign_role(ctx, model:, **)
      model.role = :vendor
    end
  end
end
