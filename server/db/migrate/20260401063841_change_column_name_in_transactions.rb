class ChangeColumnNameInTransactions < ActiveRecord::Migration[8.1]
  def change
    rename_column :transactions, :method, :payment_method
  end
end
