class Transaction < ApplicationRecord
  belongs_to :payment

  enum :status, { pending: "pending", completed: "completed", failed: "failed" }, prefix: true

  validates :ref_no, :method, :transaction_time, :status, presence: true
  validates :ref_no, uniqueness: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
end
