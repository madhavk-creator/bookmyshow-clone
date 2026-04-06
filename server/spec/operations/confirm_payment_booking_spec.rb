require "rails_helper"

RSpec.describe Bookings::ConfirmPayment do
  it "confirms a pending booking for the current user and books the locked seats" do
    fixture = build_booking_fixture(seat_count: 2)
    bundle = create_booking_bundle(
      user: fixture[:customer],
      show: fixture[:show],
      seats: fixture[:seats],
      booking_status: "pending",
      payment_status: "pending",
      seat_state_status: "locked"
    )

    result = Bookings::ConfirmPayment.call(
      current_user: fixture[:customer],
      params: { id: bundle[:booking].id }
    )

    expect(result).to be_success
    expect(result[:model].reload.status).to eq("confirmed")
    expect(bundle[:payment].reload.status).to eq("completed")
    expect(bundle[:payment].paid_at).to be_present
    expect(ShowSeatState.where(show: fixture[:show], status: "booked").count).to eq(2)
    expect(ShowSeatState.where(show: fixture[:show], status: "locked").count).to eq(0)
    expect(Transaction.where(payment: bundle[:payment], status: "completed").count).to eq(1)
  end
end
