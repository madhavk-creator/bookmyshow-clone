class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.references :show, type: :uuid, null: false, foreign_key: true
      t.references :coupon, type: :uuid, foreign_key: true
      t.decimal :total_amount, null: false, precision: 10, scale: 2, default: 0
      t.string :status, null: false, default: "pending"
      t.datetime :booking_time, null: false
      t.timestamps
    end

    add_index :bookings, [ :user_id, :booking_time ]
    add_index :bookings, [ :show_id, :status ]
  end
end
