module Users
  module Serializer
    module_function

    def call(user)
      {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role
      }
    end
  end
end
