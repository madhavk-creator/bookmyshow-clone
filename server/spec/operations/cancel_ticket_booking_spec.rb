require "rails_helper"

RSpec.describe Bookings::CancelTicket do
  it "recomputes the booking total from remaining valid tickets" do
    fixture = build_booking_fixture(seat_count: 2)
    coupon = create_coupon(
      code: "HALFPRICE",
      coupon_type: "percentage",
      discount_percentage: 50
    )
    bundle = create_booking_bundle(
      user: fixture[:customer],
      show: fixture[:show],
      seats: fixture[:seats],
      coupon: coupon,
      booking_status: "confirmed",
      payment_status: "completed",
      seat_state_status: "booked"
    )

    result = Bookings::CancelTicket.call(
      current_user: fixture[:customer],
      params: {
        booking_id: bundle[:booking].id,
        ticket_id: bundle[:tickets].first.id
      }
    )

    expect(result).to be_success
    expect(result[:model].reload.total_amount.to_d).to eq(50.to_d)
    expect(bundle[:tickets].first.reload.status).to eq("cancelled")
    expect(bundle[:tickets].last.reload.status).to eq("valid")
    expect(bundle[:payment].reload.status).to eq("completed")
  end
end
