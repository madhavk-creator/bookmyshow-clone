require "rails_helper"

RSpec.describe Bookings::ApplyCoupon do
  it "applies a coupon to a pending booking and updates payment amount" do
    fixture = build_booking_fixture(seat_count: 2)
    bundle = create_booking_bundle(
      user: fixture[:customer],
      show: fixture[:show],
      seats: fixture[:seats],
      booking_status: "pending",
      payment_status: "pending",
      seat_state_status: "locked"
    )
    coupon = create_coupon(
      code: "SAVE25",
      coupon_type: "percentage",
      discount_percentage: 25
    )

    result = Bookings::ApplyCoupon.call(
      current_user: fixture[:customer],
      params: { id: bundle[:booking].id, coupon_code: coupon.code }
    )

    expect(result).to be_success
    expect(result[:model].reload.coupon).to eq(coupon)
    expect(result[:model].total_amount.to_d).to eq(150.to_d)
    expect(bundle[:payment].reload.amount.to_d).to eq(150.to_d)
    expect(UserCouponUsage.where(booking: bundle[:booking], coupon: coupon, user: fixture[:customer]).count).to eq(1)
  end
end
