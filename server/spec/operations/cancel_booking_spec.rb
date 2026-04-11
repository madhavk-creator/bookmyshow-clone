require "rails_helper"

RSpec.describe Bookings::Cancel do
  it "discards a pending booking and releases its locked seats immediately" do
    customer = create(:user)
    show = create(:show, :bookable, seat_count: 2, base_price: 100)
    seats = show.seat_layout.seats.order(:seat_number)
    booking = create(:booking, user: customer, show: show, total_amount: 200, status: :pending)
    payment = create(:payment, booking: booking, user: customer, amount: 200, status: :pending)

    seats.each do |seat|
      create(
        :ticket,
        booking: booking,
        show: show,
        seat: seat,
        price: 100,
        seat_label: seat.label,
        section_name: seat.seat_section.name
      )

      create(
        :show_seat_state,
        show: show,
        seat: seat,
        locked_user: customer,
        lock_token: booking.lock_token,
        status: :locked
      )
    end

    result = Bookings::Cancel.call(
      current_user: customer,
      params: { id: booking.id }
    )

    expect(result).to be_success
    expect(result[:discarded]).to eq(true)
    expect(Booking.exists?(booking.id)).to eq(false)
    expect(Payment.exists?(payment.id)).to eq(false)
    expect(Ticket.where(booking_id: booking.id)).to be_empty
    expect(ShowSeatState.where(lock_token: booking.lock_token, status: "locked")).to be_empty
  end

  it "cancels a confirmed booking and keeps the booking record" do
    customer = create(:user)
    show = create(:show, :bookable, seat_count: 2, base_price: 100)
    seats = show.seat_layout.seats.order(:seat_number)
    booking = create(:booking, user: customer, show: show, total_amount: 200, status: :confirmed)
    payment = create(:payment, :completed, booking: booking, user: customer, amount: 200)

    tickets = seats.map do |seat|
      create(
        :ticket,
        booking: booking,
        show: show,
        seat: seat,
        price: 100,
        seat_label: seat.label,
        section_name: seat.seat_section.name
      )
    end

    seats.each do |seat|
      create(:show_seat_state, :booked, show: show, seat: seat)
    end

    result = Bookings::Cancel.call(
      current_user: customer,
      params: { id: booking.id }
    )

    expect(result).to be_success
    expect(result[:discarded]).to be_nil
    expect(booking.reload.status).to eq("cancelled")
    expect(payment.reload.status).to eq("refunded")
    expect(tickets.map(&:reload).map(&:status)).to all(eq("cancelled"))
  end
end
