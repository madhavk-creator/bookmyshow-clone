class CouponSerializer
  def self.one(coupon, admin: false)
    payload = {
      id: coupon.id,
      code: coupon.code,
      coupon_type: coupon.coupon_type,
      discount_amount: coupon.discount_amount,
      discount_percentage: coupon.discount_percentage,
      minimum_booking_amount: coupon.minimum_booking_amount,
      max_uses_per_user: coupon.max_uses_per_user
    }

    return payload.merge(valid_until: coupon.valid_until) unless admin

    payload.merge(
      valid_from: coupon.valid_from,
      valid_until: coupon.valid_until,
      max_total_uses: coupon.max_total_uses,
      is_active: coupon.valid_from <= Time.current && coupon.valid_until >= Time.current
    )
  end

  def self.many(coupons, admin: false) = coupons.map { |coupon| one(coupon, admin:) }
end
