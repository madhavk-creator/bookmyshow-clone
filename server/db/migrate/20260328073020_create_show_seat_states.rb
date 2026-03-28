class CreateShowSeatStates < ActiveRecord::Migration[8.1]
  def change
    create_table :show_seat_states, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :show, type: :uuid, null: false, foreign_key: true
      t.references :seat, type: :uuid, null: false, foreign_key: true
      t.string :status, null: false
      t.references :locked_by_user, type: :uuid, foreign_key: { to_table: :users }
      t.uuid :booking_id
      t.string :lock_token
      t.datetime :locked_until
      t.timestamps
    end

    add_index :show_seat_states, [ :show_id, :seat_id ], unique: true
    add_index :show_seat_states, [ :show_id, :status ]
    add_index :show_seat_states, :booking_id
  end
end
