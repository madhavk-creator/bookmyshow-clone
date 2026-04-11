require "rails_helper"

RSpec.describe Coupons::Index do
  it "loads only active coupons ordered by newest first" do
    active_older = create(:coupon, code: "SAVEOLD", created_at: 2.days.ago)
    active_newer = create(:coupon, code: "SAVENEW", created_at: 1.day.ago)
    create(:coupon, code: "EXPIRED", valid_from: 3.days.ago, valid_until: 1.day.ago)

    result = Coupons::Index.call

    expect(result).to be_success
    expect(result[:records].pluck(:code)).to eq([ active_newer.code, active_older.code ])
  end

  it "loads only eligible coupons for a pending booking and user" do
    user = create(:user)
    show = create(:show, :bookable, seat_count: 2, base_price: 100)
    seats = show.seat_layout.seats.order(:seat_number)
    booking = create(:booking, user: user, show: show, total_amount: 200, status: :pending)
    payment = create(:payment, booking: booking, user: user, amount: 200, status: :pending)

    seats.each do |seat|
      create(:ticket, booking: booking, show: show, seat: seat, price: 100, seat_label: seat.label, section_name: seat.seat_section.name)
      create(:show_seat_state, show: show, seat: seat, locked_user: user, lock_token: booking.lock_token, status: :locked)
    end

    eligible = create(:coupon, code: "ELIGIBLE", max_uses_per_user: 2, minimum_booking_amount: 100)
    exhausted = create(:coupon, code: "EXHAUSTED", max_uses_per_user: 1, max_total_uses: nil)
    too_large = create(:coupon, code: "MIN500", minimum_booking_amount: 500, max_uses_per_user: nil)

    old_confirmed_booking = create(:booking, user: user, show: show, coupon: exhausted, status: :confirmed)
    create(:user_coupon_usage, coupon: exhausted, user: user, booking: old_confirmed_booking)

    result = Coupons::Index.call(
      current_user: user,
      params: { booking_id: booking.id }
    )

    expect(result).to be_success
    expect(result[:records].map(&:code)).to include(eligible.code)
    expect(result[:records].map(&:code)).not_to include(exhausted.code)
    expect(result[:records].map(&:code)).not_to include(too_large.code)
    expect(Payment.exists?(payment.id)).to eq(true)
  end
end

RSpec.describe Coupons::Validate do
  it "returns coupon payload for a valid coupon and subtotal" do
    coupon = create(:coupon, :percentage, code: "SAVE25", discount_percentage: 25, max_uses_per_user: nil)

    result = Coupons::Validate.call(
      params: { code: "save25", booking_amount: 400 }
    )

    expect(result).to be_success
    expect(result[:payload][:valid]).to eq(true)
    expect(result[:payload][:code]).to eq("SAVE25")
    expect(result[:payload][:discount_amount]).to eq(100.0)
    expect(result[:payload][:final_amount]).to eq(300.0)
  end

  it "fails when coupon code is invalid" do
    result = Coupons::Validate.call(
      params: { code: "missing", booking_amount: 200 }
    )

    expect(result).not_to be_success
    expect(result[:errors]).to eq(base: [ "Invalid coupon code" ])
  end

  it "fails when booking_amount is missing" do
    coupon = create(:coupon, code: "SAVE10")

    result = Coupons::Validate.call(
      params: { code: coupon.code }
    )

    expect(result).not_to be_success
    expect(result[:errors]).to eq(booking_amount: [ "is required" ])
  end

  it "fails when per-user coupon usage limit is reached" do
    user = create(:user)
    coupon = create(:coupon, code: "LIMIT1", max_uses_per_user: 1, max_total_uses: nil)
    booking = create(:booking, user: user, coupon: coupon)
    create(:user_coupon_usage, coupon: coupon, user: user, booking: booking)

    result = Coupons::Validate.call(
      current_user: user,
      params: { code: coupon.code, booking_amount: 500 }
    )

    expect(result).not_to be_success
    expect(result[:errors]).to eq(base: [ "You have already used this coupon the maximum number of times" ])
  end
end

RSpec.describe Admin::Coupons::Create do
  it "rejects amount coupons whose discount exceeds the minimum booking amount" do
    result = described_class.call(
      params: {
        code: "FLAT500",
        coupon_type: "amount",
        discount_amount: 500,
        minimum_booking_amount: 300,
        valid_from: 1.hour.from_now,
        valid_until: 2.hours.from_now
      }
    )

    expect(result).not_to be_success
    expect(result[:errors]).to include(discount_amount: [ "Discount amount cannot be greater than the minimum booking amount" ])
  end

  it "rejects coupon codes with special characters" do
    result = described_class.call(
      params: {
        code: "TEST!)",
        coupon_type: "percentage",
        discount_percentage: 10,
        valid_from: 1.hour.from_now,
        valid_until: 2.hours.from_now
      }
    )

    expect(result).not_to be_success
    expect(result[:errors]).to include(code: [ "Code must contain only uppercase letters and numbers" ])
  end
end

RSpec.describe Admin::Coupons::Destroy do
  it "archives a coupon instead of deleting it" do
    coupon = create(:coupon)

    result = described_class.call(params: { id: coupon.id })

    expect(result).to be_success
    expect(Coupon.find_by(id: coupon.id)).to be_present
    expect(coupon.reload.valid_until).to be < Time.current
  end
end
