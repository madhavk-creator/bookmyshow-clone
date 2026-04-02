module Vendors
  class Register < Users::Register
    private

    def assign_role(ctx, model:, **)
      model.role = :vendor
    end
  end
end