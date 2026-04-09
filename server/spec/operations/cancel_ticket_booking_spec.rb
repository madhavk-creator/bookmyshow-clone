require "rails_helper"

RSpec.describe Bookings::CancelTicket do
  it "recomputes the booking total from remaining valid tickets" do
    customer = create(:user)
    show = create(:show, :bookable, seat_count: 2, base_price: 100)
    seats = show.seat_layout.seats.order(:seat_number)
    coupon = create(:coupon, :percentage, code: "HALFPRICE", discount_percentage: 50)
    booking = create(:booking, user: customer, show: show, coupon: coupon, total_amount: 100, status: :confirmed)
    tickets = seats.map do |seat|
      create(:ticket, booking: booking, show: show, seat: seat, price: 100, seat_label: seat.label, section_name: seat.seat_section.name)
    end
    payment = create(:payment, :completed, booking: booking, user: customer, amount: 100)
    seats.each do |seat|
      create(:show_seat_state, :booked, show: show, seat: seat)
    end

    result = Bookings::CancelTicket.call(
      current_user: customer,
      params: {
        booking_id: booking.id,
        ticket_id: tickets.first.id
      }
    )

    expect(result).to be_success
    expect(result[:model].reload.total_amount).to eq(50.0)
    expect(tickets.first.reload.status).to eq("cancelled")
    expect(tickets.last.reload.status).to eq("valid")
    expect(payment.reload.status).to eq("completed")
  end
end
