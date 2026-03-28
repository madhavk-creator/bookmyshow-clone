class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :payment, type: :uuid, null: false, foreign_key: true
      t.string :ref_no, null: false
      t.string :method, null: false
      t.decimal :amount, null: false, precision: 10, scale: 2
      t.datetime :transaction_time, null: false
      t.string :status, null: false, default: "pending"
      t.timestamps
    end

    add_index :transactions, :ref_no, unique: true
    add_index :transactions, [ :payment_id, :status ]
  end
end
