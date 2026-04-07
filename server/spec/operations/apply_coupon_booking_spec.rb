require "rails_helper"

RSpec.describe Bookings::ApplyCoupon do
  it "applies a coupon to a pending booking and updates payment amount" do
    customer = create(:user)
    show = create(:show, :bookable, seat_count: 2, base_price: 100)
    seats = show.seat_layout.seats.order(:seat_number)
    booking = create(:booking, user: customer, show: show, total_amount: 200, status: :pending)
    payment = create(:payment, booking: booking, user: customer, amount: 200, status: :pending)
    seats.each do |seat|
      create(:ticket, booking: booking, show: show, seat: seat, price: 100, seat_label: seat.label, section_name: seat.seat_section.name)
      create(:show_seat_state, show: show, seat: seat, locked_user: customer, lock_token: booking.lock_token, status: :locked)
    end
    coupon = create(:coupon, :percentage, code: "SAVE25", discount_percentage: 25)

    result = Bookings::ApplyCoupon.call(
      current_user: customer,
      params: { id: booking.id, coupon_code: coupon.code }
    )

    expect(result).to be_success
    expect(result[:model].reload.coupon).to eq(coupon)
    expect(result[:model].total_amount.to_d).to eq(150.to_d)
    expect(payment.reload.amount.to_d).to eq(150.to_d)
    expect(UserCouponUsage.where(booking: booking, coupon: coupon, user: customer).count).to eq(1)
  end
end
