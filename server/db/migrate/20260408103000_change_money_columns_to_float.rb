class ChangeMoneyColumnsToFloat < ActiveRecord::Migration[8.1]
  def up
    change_column :bookings, :total_amount, :float, null: false, default: 0.0
    change_column :coupons, :discount_amount, :float
    change_column :coupons, :minimum_booking_amount, :float
    change_column :payments, :amount, :float, null: false
    change_column :payment_refunds, :amount, :float, null: false
    change_column :show_section_prices, :base_price, :float, null: false
    change_column :tickets, :price, :float, null: false
    change_column :transactions, :amount, :float, null: false
  end

  def down
    change_column :bookings, :total_amount, :decimal, precision: 10, scale: 2, null: false, default: 0
    change_column :coupons, :discount_amount, :decimal, precision: 10, scale: 2
    change_column :coupons, :minimum_booking_amount, :decimal, precision: 10, scale: 2
    change_column :payments, :amount, :decimal, precision: 10, scale: 2, null: false
    change_column :payment_refunds, :amount, :decimal, precision: 10, scale: 2, null: false
    change_column :show_section_prices, :base_price, :decimal, precision: 10, scale: 2, null: false
    change_column :tickets, :price, :decimal, precision: 10, scale: 2, null: false
    change_column :transactions, :amount, :decimal, precision: 10, scale: 2, null: false
  end
end
