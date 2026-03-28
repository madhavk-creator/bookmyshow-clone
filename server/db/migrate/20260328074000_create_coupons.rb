class CreateCoupons < ActiveRecord::Migration[8.1]
  def change
    create_table :coupons, id: :uuid, default: "gen_random_uuid()" do |t|
      t.string :code, null: false
      t.text :description
      t.string :coupon_type, null: false
      t.decimal :discount_amount, precision: 10, scale: 2
      t.decimal :discount_percentage, precision: 5, scale: 2
      t.decimal :minimum_booking_amount, precision: 10, scale: 2
      t.integer :max_uses_per_user
      t.integer :max_total_uses
      t.datetime :valid_from, null: false
      t.datetime :valid_until, null: false
      t.timestamps
    end

    add_index :coupons, :code, unique: true
  end
end
