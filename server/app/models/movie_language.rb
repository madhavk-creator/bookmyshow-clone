class MovieLanguage < ApplicationRecord
  belongs_to :movie
  belongs_to :language
  has_many :shows, dependent: :restrict_with_error

  enum :language_type, { original: "original", dubbed: "dubbed", subtitled: "subtitled" }, prefix: true

  validates :language_id, uniqueness: { scope: :movie_id }
  validates :language_type, presence: true
end
