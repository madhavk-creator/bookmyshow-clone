class FixBookingLockTokenSchema < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :lock_token, :string unless column_exists?(:bookings, :lock_token)
    add_index :bookings, :lock_token unless index_exists?(:bookings, :lock_token)
    add_index :show_seat_states, :lock_token unless index_exists?(:show_seat_states, :lock_token)
  end
end
