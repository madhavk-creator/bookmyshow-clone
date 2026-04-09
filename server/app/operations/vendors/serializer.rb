module Vendors
  module Serializer
    module_function

    def call(vendor)
      {
        id: vendor.id,
        name: vendor.name,
        email: vendor.email,
        phone: vendor.phone,
        is_active: vendor.is_active,
        theatres_count: vendor.theatres.size,
        created_at: vendor.created_at
      }
    end

    def many(vendors)
      vendors.map { |vendor| call(vendor) }
    end
  end
end
