class PaymentRefund < ApplicationRecord
  belongs_to :payment
  belongs_to :ticket

  enum :status, { pending: "pending", completed: "completed", failed: "failed" }, prefix: true

  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true

  validate :amount_does_not_exceed_ticket_price

  private
  def amount_does_not_exceed_ticket_price
    return if ticket.blank? || amount.blank?
    if amount > ticket.price
      errors.add(:amount, "cannot exceed the original ticket price")
    end
  end
end
