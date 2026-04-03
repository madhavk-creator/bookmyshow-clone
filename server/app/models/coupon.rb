class Coupon < ApplicationRecord
  has_many :bookings, dependent: :restrict_with_error
  has_many :user_coupon_usages, dependent: :restrict_with_error

  enum :coupon_type, { amount: "amount", percentage: "percentage" }, prefix: true

  before_validation :normalize_code

  validates :code, :coupon_type, :valid_from, :valid_until, presence: true
  validates :code, uniqueness: { case_sensitive: false }
  validates :discount_amount, numericality: { greater_than: 0 }, allow_nil: true
  validates :discount_percentage, numericality: { greater_than: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :minimum_booking_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :max_uses_per_user, :max_total_uses,
            numericality: { only_integer: true, greater_than: 0 },
            allow_nil: true
  validate :validity_window_order
  validate :discount_fields_match_type

  scope :active, -> {
    where('valid_from <= ? AND valid_until >= ?', Time.current, Time.current)
  }

  def applicable?(booking_amount)
    Time.current.between?(valid_from, valid_until) &&
      (minimum_booking_amount.nil? || booking_amount >= minimum_booking_amount) &&
      (max_total_uses.nil? || user_coupon_usages.count < max_total_uses)
  end

  def apply(booking_amount)
    return booking_amount unless applicable?(booking_amount)

    if coupon_type_amount?
      [booking_amount - discount_amount, 0].max
    else
      booking_amount * (1 - discount_percentage / 100.0)
    end
  end

  private

  def normalize_code
    self.code = code.to_s.strip.upcase if code.present?
  end

  def validity_window_order
    return if valid_from.blank? || valid_until.blank?
    return if valid_until > valid_from

    errors.add(:valid_until, "must be after valid_from")
  end

  def discount_fields_match_type
    case coupon_type
    when "amount"
      errors.add(:discount_amount, "must be present for amount coupons") if discount_amount.blank?
    when "percentage"
      errors.add(:discount_percentage, "must be present for percentage coupons") if discount_percentage.blank?
    end
  end
end
