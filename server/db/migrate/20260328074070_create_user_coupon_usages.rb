class CreateUserCouponUsages < ActiveRecord::Migration[8.1]
  def change
    create_table :user_coupon_usages, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :coupon, type: :uuid, null: false, foreign_key: true
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.references :booking, type: :uuid, null: false, foreign_key: true, index: false
      t.datetime :used_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamps
    end

    add_index :user_coupon_usages, [ :coupon_id, :user_id ]
    add_index :user_coupon_usages, :booking_id, unique: true
  end
end
