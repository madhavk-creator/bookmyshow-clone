class Review < ApplicationRecord
  belongs_to :movie
  belongs_to :user

  validates :user_id, uniqueness: { scope: :movie_id }
  validates :reviewed_on, presence: true
  validates :rating, numericality: { greater_than_or_equal_to: 1.0, less_than_or_equal_to: 5.0 }
end
