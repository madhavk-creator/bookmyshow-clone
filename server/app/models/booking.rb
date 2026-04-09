class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :show
  belongs_to :coupon, optional: true

  has_many :tickets, dependent: :destroy

  has_many :payments, dependent: :destroy

  has_many :user_coupon_usages, dependent: :destroy

  enum :status, { pending: "pending", confirmed: "confirmed",
    cancelled: "cancelled", expired: "expired" }, prefix: true

  before_validation :assign_booking_time, on: :create

  validates :booking_time, :status, presence: true

  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }

  validates :lock_token, presence: true, uniqueness: true

  def valid_tickets_subtotal
    tickets.where(status: "valid").sum(:price).to_f
  end

  def refresh_expiration!
    return self unless status_pending?

    active_locks = ShowSeatState.where(
      lock_token: lock_token,
      status: "locked"
    ).where("locked_until >= ?", Time.current)

    return self if active_locks.exists?

    ShowSeatState.where(lock_token: lock_token, status: "locked").delete_all
    update!(status: "expired")
    self
  end

  private

  def assign_booking_time
    self.booking_time ||= Time.current
  end
end
