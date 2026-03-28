class UserCouponUsage < ApplicationRecord
  belongs_to :coupon
  belongs_to :user
  belongs_to :booking

  validates :used_at, presence: true
  validate :booking_matches_user
  validate :booking_matches_coupon

  private

  def booking_matches_user
    return if booking.blank? || user.blank?
    return if booking.user_id == user_id

    errors.add(:user, "must match the booking user")
  end

  def booking_matches_coupon
    return if booking.blank? || coupon.blank?
    return if booking.coupon_id == coupon_id

    errors.add(:coupon, "must match the booking coupon")
  end
end
