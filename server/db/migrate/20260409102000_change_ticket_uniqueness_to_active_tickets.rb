class ChangeTicketUniquenessToActiveTickets < ActiveRecord::Migration[8.1]
  def change
    remove_index :tickets, name: "index_tickets_on_show_id_and_seat_id"

    add_index :tickets,
              [ :show_id, :seat_id ],
              unique: true,
              where: "status = 'valid'",
              name: "index_tickets_on_show_id_and_seat_id_valid"
  end
end
