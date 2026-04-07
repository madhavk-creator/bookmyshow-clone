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
    expect(result[:payload][:discount_amount].to_d).to eq(100.to_d)
    expect(result[:payload][:final_amount].to_d).to eq(300.to_d)
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
