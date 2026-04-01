class UserCouponUsage < ApplicationRecord
  belongs_to :coupon
  belongs_to :user
  belongs_to :booking

  before_validation :assign_used_at, on: :create

  validates :used_at, presence: true
  validate :booking_matches_user
  validate :booking_matches_coupon

  private

  def assign_used_at
    self.used_at ||= Time.current
  end

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
