class AddLockTokenToBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :lock_token, :string
    add_index :show_seat_states, :lock_token
  end
end
