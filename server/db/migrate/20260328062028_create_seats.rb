class CreateSeats < ActiveRecord::Migration[8.1]
  def change
    create_table :seats, id: :uuid, default: "gen_random_uuid()" do |t|
      t.uuid :seat_layout_id, null: false
      t.uuid :seat_section_id, null: false
      t.string :row_label, null: false
      t.integer :seat_number, null: false
      t.string :label, null: false
      t.integer :grid_row, null: false
      t.integer :grid_column, null: false
      t.integer :x_span, null: false, default: 1
      t.integer :y_span, null: false, default: 1
      t.string :seat_kind, null: false, default: "standard"
      t.boolean :is_accessible, null: false, default: false
      t.boolean :is_active, null: false, default: true
      t.timestamps
    end

    add_index :seats, [ :seat_layout_id, :label ], unique: true
    add_index :seats, [ :seat_layout_id, :grid_row, :grid_column ], unique: true
    add_index :seats, [ :seat_layout_id, :seat_section_id ]
  end
end
