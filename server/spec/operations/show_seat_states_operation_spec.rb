require "rails_helper"

RSpec.describe ShowSeatStates::Availability do
  it "returns section payload and status counts" do
    show = create(:show, :bookable, seat_count: 2, base_price: 150)
    seats = show.seat_layout.seats.order(:seat_number).to_a

    create(:show_seat_state, :blocked, show: show, seat: seats.first)
    seats.last.update!(is_active: false)

    result = ShowSeatStates::Availability.call(
      params: { show_id: show.id }
    )

    expect(result).to be_success
    payload = result[:payload]
    expect(payload[:show_id]).to eq(show.id)
    expect(payload[:blocked_count]).to eq(1)
    expect(payload[:inactive_count]).to eq(1)
    expect(payload[:available_count]).to eq(0)
    expect(payload[:sections]).to be_present
  end
end

RSpec.describe ShowSeatStates::Block do
  it "fails for non-admin users" do
    show = create(:show, :bookable, seat_count: 1)
    seat = show.seat_layout.seats.first
    user = create(:user)

    result = ShowSeatStates::Block.call(
      current_user: user,
      params: { show_id: show.id, seat_id: seat.id }
    )

    expect(result).not_to be_success
    expect(result[:errors]).to eq(base: [ "Not authorized to block seats" ])
  end
end

RSpec.describe ShowSeatStates::Unblock do
  it "unblocks a blocked seat for admins" do
    show = create(:show, :bookable, seat_count: 1)
    seat = show.seat_layout.seats.first
    admin = create(:user, :admin)
    create(:show_seat_state, :blocked, show: show, seat: seat)

    result = ShowSeatStates::Unblock.call(
      current_user: admin,
      params: { show_id: show.id, seat_id: seat.id }
    )

    expect(result).to be_success
    expect(ShowSeatState.find_by(show_id: show.id, seat_id: seat.id)).to be_nil
  end
end
