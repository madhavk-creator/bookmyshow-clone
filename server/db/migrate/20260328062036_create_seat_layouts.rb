class CreateSeatLayouts < ActiveRecord::Migration[8.1]
  def change
    create_table :seat_layouts, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :screen, type: :uuid, null: false, foreign_key: true
      t.integer :version_number, null: false
      t.string :name, null: false
      t.string :status, null: false, default: "draft"
      t.integer :total_rows, null: false
      t.integer :total_columns, null: false
      t.integer :total_seats, null: false, default: 0
      t.string :screen_label
      t.jsonb :legend_json, null: false, default: {}
      t.datetime :published_at
      t.timestamps
    end

    add_index :seat_layouts, [ :screen_id, :version_number ], unique: true
    add_index :seat_layouts, [ :screen_id, :status ]
    add_index :seat_layouts, :screen_id,
              unique: true,
              where: "status = 'published'",
              name: "index_seat_layouts_one_published_per_screen"

    create_table :seat_sections, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :seat_layout, type: :uuid, null: false, foreign_key: true
      t.string :code, null: false
      t.string :name, null: false
      t.string :color_hex
      t.integer :rank, null: false, default: 0
      t.timestamps
    end

    add_index :seat_sections, [ :seat_layout_id, :code ], unique: true
    add_index :seat_sections, [ :seat_layout_id, :rank ]

    add_foreign_key :seats, :seat_layouts
    add_foreign_key :seats, :seat_sections
  end
end
