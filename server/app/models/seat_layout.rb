class SeatLayout < ApplicationRecord
  belongs_to :screen
  has_many :seat_sections, dependent: :destroy
  has_many :seats, dependent: :destroy
  has_many :shows, dependent: :restrict_with_error

  enum :status, { draft: "draft", published: "published", archived: "archived" }, prefix: true

  validates :name, presence: true
  validates :version_number, uniqueness: { scope: :screen_id }
  validates :total_rows, :total_columns, numericality: { only_integer: true, greater_than: 0 }
  validates :total_seats, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :published_first, -> { order(published_at: :desc, created_at: :desc) }
end
