require "rails_helper"

RSpec.describe Bookings::ConfirmPayment do
  it "confirms a pending booking for the current user and books the locked seats" do
    customer = create(:user)
    show = create(:show, :bookable, seat_count: 2, base_price: 100)
    seats = show.seat_layout.seats.order(:seat_number)
    coupon = create(:coupon, :percentage, code: "SAVE25", discount_percentage: 25)
    booking = create(:booking, user: customer, show: show, coupon: coupon, total_amount: 150, status: :pending)

    seats.each do |seat|
      create(:ticket, booking: booking,
        show: show, seat: seat, price: 100,
        seat_label: seat.label,
        section_name: seat.seat_section.name
      )
      create(:show_seat_state,
      show: show,
      seat: seat,
      locked_user: customer,
      lock_token: booking.lock_token, status: :locked)
    end
    payment = create(:payment, booking: booking, user: customer, amount: 150, status: :pending)

    result = Bookings::ConfirmPayment.call(
      current_user: customer,
      params: { id: booking.id }
    )

    expect(result).to be_success
    expect(result[:model].reload.status).to eq("confirmed")
    expect(payment.reload.status).to eq("completed")
    expect(payment.paid_at).to be_present
    expect(ShowSeatState.where(show: show, status: "booked").count).to eq(2)
    expect(ShowSeatState.where(show: show, status: "locked").count).to eq(0)
    expect(Transaction.where(payment: payment, status: "completed").count).to eq(1)
    expect(UserCouponUsage.where(booking: booking, coupon: coupon, user: customer).count).to eq(1)
  end
end
