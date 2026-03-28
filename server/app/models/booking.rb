class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :show
  belongs_to :coupon, optional: true

  has_many :tickets, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :show_seat_states, dependent: :nullify
  has_many :user_coupon_usages, dependent: :destroy

  enum :status, { pending: "pending", confirmed: "confirmed", cancelled: "cancelled", expired: "expired" }, prefix: true

  before_validation :assign_booking_time, on: :create

  validates :booking_time, :status, presence: true
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }

  private

  def assign_booking_time
    self.booking_time ||= Time.current
  end
end
