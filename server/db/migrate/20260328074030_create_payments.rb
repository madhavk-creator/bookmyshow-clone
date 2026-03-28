class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :booking, type: :uuid, null: false, foreign_key: true
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.decimal :amount, null: false, precision: 10, scale: 2
      t.string :status, null: false, default: "pending"
      t.datetime :paid_at
      t.timestamps
    end

    add_index :payments, [ :user_id, :status ]
  end
end
