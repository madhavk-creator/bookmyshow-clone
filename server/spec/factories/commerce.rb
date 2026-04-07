FactoryBot.define do
  factory :coupon do
    sequence(:code) { |n| "SAVE#{100 + n}" }
    coupon_type { :amount }
    discount_amount { 100 }
    discount_percentage { nil }
    minimum_booking_amount { 0 }
    valid_from { 1.day.ago }
    valid_until { 2.days.from_now }
    max_uses_per_user { 5 }
    max_total_uses { 100 }

    trait :percentage do
      coupon_type { :percentage }
      discount_amount { nil }
      discount_percentage { 10 }
    end
  end

  factory :booking do
    user
    show
    coupon { nil }
    booking_time { Time.current }
    total_amount { 0 }
    status { :pending }
    lock_token { SecureRandom.uuid }
  end

  factory :ticket do
    booking
    show { booking.show }
    seat do
      section = show.seat_layout.seat_sections.first || create(:seat_section, seat_layout: show.seat_layout)
      association :seat, seat_layout: show.seat_layout, seat_section: section
    end
    seat_label { seat.label }
    section_name { seat.seat_section.name }
    price { 100 }
    status { :valid }
  end

  factory :payment do
    booking
    user { booking.user }
    amount { booking.total_amount }
    status { :pending }
    paid_at { nil }

    trait :completed do
      status { :completed }
      paid_at { Time.current }
    end
  end

  factory :transaction do
    payment
    sequence(:ref_no) { |n| "TXN-#{1000 + n}" }
    payment_method { "card" }
    amount { payment.amount }
    transaction_time { Time.current }
    status { :completed }
  end

  factory :user_coupon_usage do
    booking do
      coupon = association(:coupon)
      user = association(:user)
      association :booking, user: user, coupon: coupon
    end
    coupon { booking.coupon }
    user { booking.user }
    used_at { Time.current }
  end
end
