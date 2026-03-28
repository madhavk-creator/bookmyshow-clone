class CreateTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :tickets, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :booking, type: :uuid, null: false, foreign_key: true
      t.references :show, type: :uuid, null: false, foreign_key: true
      t.references :seat, type: :uuid, null: false, foreign_key: true
      t.string :seat_label, null: false
      t.string :section_name, null: false
      t.decimal :price, null: false, precision: 10, scale: 2
      t.string :status, null: false, default: "valid"
      t.timestamps
    end

    add_index :tickets, [ :show_id, :seat_id ], unique: true
    add_index :tickets, [ :booking_id, :status ]
  end
end
