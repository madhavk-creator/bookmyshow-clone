require "rails_helper"

RSpec.describe Bookings::Create do # let
  it "creates a pending booking with tickets and payment" do # context
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
    expect(result[:model].total_amount).to eq(200.0)
  end

  it "fails before locking or pricing when any requested seat id is invalid" do
    customer = create(:user) # before
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

  it "allows rebooking a seat after its earlier ticket was cancelled" do
    customer = create(:user)
    show = create(:show, :bookable, seat_count: 1, base_price: 100)
    seat = show.seat_layout.seats.order(:seat_number).first
    old_booking = create(:booking, user: customer, show: show, status: :cancelled)

    create(
      :ticket,
      booking: old_booking,
      show: show,
      seat: seat,
      price: 100,
      seat_label: seat.label,
      section_name: seat.seat_section.name,
      status: :cancelled
    )

    result = Bookings::Create.call(
      current_user: customer,
      params: {
        show_id: show.id,
        seat_ids: [ seat.id ]
      }
    )

    expect(result).to be_success
    expect(result[:model]).to be_persisted
    expect(result[:model].tickets.reload.pluck(:seat_id)).to eq([ seat.id ])
  end

  it "releases expired locks before trying to reserve seats" do
    customer = create(:user)
    show = create(:show, :bookable, seat_count: 1, base_price: 100)
    seat = show.seat_layout.seats.order(:seat_number).first
    stale_booking = create(:booking, user: customer, show: show, total_amount: 100, status: :pending)
    stale_payment = create(:payment, booking: stale_booking, user: customer, amount: 100, status: :pending)

    create(
      :ticket,
      booking: stale_booking,
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
      status: :locked,
      locked_user: customer,
      lock_token: stale_booking.lock_token,
      locked_until: 10.minutes.ago
    )

    result = Bookings::Create.call(
      current_user: customer,
      params: {
        show_id: show.id,
        seat_ids: [ seat.id ]
      }
    )

    expect(result).to be_success
    expect(ShowSeatState.where(show: show, seat: seat, status: "locked").count).to eq(1)
    expect(ShowSeatState.where(show: show, seat: seat).pluck(:lock_token).compact).to eq([ result[:model].lock_token ])
    expect(Booking.exists?(stale_booking.id)).to eq(false)
    expect(Ticket.where(booking_id: stale_booking.id)).to be_empty
    expect(Payment.exists?(stale_payment.id)).to eq(false)
  end

  it "reuses the same pending booking and lock window when adding seats for the same show" do
    customer = create(:user)
    show = create(:show, :bookable, seat_count: 3, base_price: 100)
    seats = show.seat_layout.seats.order(:seat_number)

    first_result = Bookings::Create.call(
      current_user: customer,
      params: {
        show_id: show.id,
        seat_ids: [ seats.first.id ]
      }
    )

    first_booking = first_result[:model]
    first_lock_until = ShowSeatState.find_by(show: show, seat: seats.first, status: "locked").locked_until

    second_result = Bookings::Create.call(
      current_user: customer,
      params: {
        show_id: show.id,
        seat_ids: [ seats.second.id ]
      }
    )

    expect(second_result).to be_success
    expect(second_result[:model].id).to eq(first_booking.id)
    expect(second_result[:model].tickets.reload.where(status: "valid").count).to eq(2)
    expect(second_result[:payment].reload.amount).to eq(200.0)
    expect(
      ShowSeatState.where(show: show, seat_id: [ seats.first.id, seats.second.id ], status: "locked").pluck(:lock_token).uniq
    ).to eq([ first_booking.lock_token ])
    expect(
      ShowSeatState.where(show: show, seat_id: [ seats.first.id, seats.second.id ], status: "locked").pluck(:locked_until).uniq
    ).to eq([ first_lock_until ])
  end
end
