class Review < ApplicationRecord
  belongs_to :movie
  belongs_to :user

  validates :rating, presence: true,
            numericality: { greater_than_or_equal_to: 1.0,
                            less_than_or_equal_to: 5.0 }
  validates :description, presence: true, length: { minimum: 10, maximum: 2000 }
  validates :reviewed_on, presence: true
  validates :user_id, uniqueness: { scope: :movie_id,
                                    message: "has already reviewed this movie" }
end
