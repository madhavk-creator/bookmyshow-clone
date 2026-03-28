class PaymentRefund < ApplicationRecord
  belongs_to :payment
  belongs_to :ticket

  enum :status, { pending: "pending", completed: "completed", failed: "failed" }, prefix: true

  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true
end
