class Movie < ApplicationRecord
  has_many :movie_languages, dependent: :destroy
  has_many :languages, through: :movie_languages
  has_many :movie_formats, dependent: :destroy
  has_many :formats, through: :movie_formats
  has_many :cast_members, dependent: :destroy
  has_many :shows, dependent: :restrict_with_error
  has_many :reviews, dependent: :destroy

  enum :rating, { u: "U", ua: "UA", a: "A", s: "S" }, prefix: true

  validates :title, :genre, :rating, presence: true
  validates :running_time, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
end
