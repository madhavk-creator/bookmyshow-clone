class Payment < ApplicationRecord
  belongs_to :booking
  belongs_to :user

  has_many :transactions, dependent: :destroy
  has_many :payment_refunds, dependent: :destroy

  enum :status, { pending: "pending", completed: "completed", failed: "failed", refunded: "refunded" }, prefix: true

  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true
  validate :user_matches_booking

  private

  def user_matches_booking
    return if booking.blank? || user.blank?
    return if booking.user_id == user_id

    errors.add(:user, "must match the booking users")
  end
end
