class AddBookingForeignKeyToShowSeatStates < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :show_seat_states, :bookings
  end
end
