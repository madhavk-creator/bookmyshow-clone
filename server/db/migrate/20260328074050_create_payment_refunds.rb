class CreatePaymentRefunds < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_refunds, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :payment, type: :uuid, null: false, foreign_key: true
      t.references :ticket, type: :uuid, null: false, foreign_key: true
      t.decimal :amount, null: false, precision: 10, scale: 2
      t.datetime :refunded_at
      t.string :status, null: false, default: "pending"
      t.timestamps
    end

    add_index :payment_refunds, [ :payment_id, :ticket_id ]
    add_index :payment_refunds, [ :ticket_id, :status ]
  end
end
