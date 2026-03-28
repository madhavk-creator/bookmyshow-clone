class MovieFormat < ApplicationRecord
  belongs_to :movie
  belongs_to :format
  has_many :shows, dependent: :restrict_with_error

  validates :format_id, uniqueness: { scope: :movie_id }
end
