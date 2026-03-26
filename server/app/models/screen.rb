class Screen < ApplicationRecord
  belongs_to :theatre
  has_many :screen_capabilities, dependent: :destroy
  has_many :formats, through: :screen_capabilities
  has_one :seat_layout, dependent: :destroy
  has_many :seats, dependent: :restrict_with_error
  has_many :shows, dependent: :restrict_with_error

  enum :status, { active: "active", inactive: "inactive" }

  validates :name, presence: true, uniqueness: { scope: :theatre_id }
  validates :total_rows, :total_columns, numericality: { only_integer: true, greater_than: 0 }
  validates :total_seats, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
