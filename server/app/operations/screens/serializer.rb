module Screens
  module Serializer
    module_function

    def call(screen)
      {
        id: screen.id,
        theatre_id: screen.theatre_id,
        name: screen.name,
        status: screen.status,
        total_rows: screen.total_rows,
        total_columns: screen.total_columns,
        total_seats: screen.total_seats,
        formats: screen.formats.map { |format| { id: format.id, name: format.name, code: format.code } },
        created_at: screen.created_at
      }
    end

    def many(screens)
      screens.map { |screen| call(screen) }
    end
  end
end
