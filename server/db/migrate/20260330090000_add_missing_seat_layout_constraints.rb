class AddMissingSeatLayoutConstraints < ActiveRecord::Migration[8.1]
  def change
    if index_exists?(:seat_sections, [ :seat_layout_id, :rank ], name: "index_seat_sections_on_seat_layout_id_and_rank")
      remove_index :seat_sections, name: "index_seat_sections_on_seat_layout_id_and_rank"
    end

    add_index :seat_sections, [ :seat_layout_id, :rank ],
              unique: true,
              name: "index_seat_sections_on_seat_layout_id_and_rank"

    unless index_exists?(:seat_layouts, :screen_id, name: "index_seat_layouts_one_published_per_screen")
      add_index :seat_layouts, :screen_id,
                unique: true,
                where: "status = 'published'",
                name: "index_seat_layouts_one_published_per_screen"
    end
  end
end
