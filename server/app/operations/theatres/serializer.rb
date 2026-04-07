module Theatres
  module Serializer
    module_function

    def call(theatre)
      {
        id: theatre.id,
        vendor_id: theatre.vendor_id,
        name: theatre.name,
        building_name: theatre.building_name,
        street_address: theatre.street_address,
        city: {
          id: theatre.city.id,
          name: theatre.city.name,
          state: theatre.city.state
        },
        pincode: theatre.pincode,
        created_at: theatre.created_at
      }
    end

    def many(theatres)
      theatres.map { |theatre| call(theatre) }
    end
  end
end
