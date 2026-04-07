require "rails_helper"

RSpec.describe Bookings::Create do #let
  it "creates a pending booking with tickets and payment" do #context
    customer = create(:user)
    show = create(:show, :bookable, seat_count: 3, base_price: 100)
    seats = show.seat_layout.seats.order(:seat_number)

    result = Bookings::Create.call(
      current_user: customer,
      params: {
        show_id: show.id,
        seat_ids: seats.first(2).map(&:id)
      }
    )

    expect(result).to be_success
    expect(result[:model]).to be_persisted
    expect(result[:model].status).to eq("pending")
    expect(result[:model].tickets.count).to eq(2)
    expect(result[:payment].status).to eq("pending")
    expect(result[:model].total_amount.to_d).to eq(200.to_d)
  end

  it "fails before locking or pricing when any requested seat id is invalid" do
    customer = create(:user) #before
    show = create(:show, :bookable, seat_count: 2)
    seats = show.seat_layout.seats.order(:seat_number)
    booking_count = Booking.count
    seat_state_count = ShowSeatState.count

    result = Bookings::Create.call(
      current_user: customer,
      params: {
        show_id: show.id,
        seat_ids: [ seats.first.id, SecureRandom.uuid ]
      }
    )

    expect(result).not_to be_success
    expect(result[:errors]).to have_key(:seat_ids)
    expect(Booking.count).to eq(booking_count)
    expect(ShowSeatState.count).to eq(seat_state_count)
  end
end
