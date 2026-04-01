class SeatSection < ApplicationRecord
  belongs_to :seat_layout
  has_many :seats, dependent: :destroy
  has_many :show_section_prices, dependent: :restrict_with_error

  validates :code, :name, presence: true
  validates :code, uniqueness: { scope: :seat_layout_id, case_sensitive: false }
  validates :rank, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :color_hex,
            format: { with: /\A#(?:\h{3}|\h{6})\z/, message: "must be a valid hex color" },
            allow_blank: true
  validates :rank, uniqueness: { scope: :seat_layout_id }

  before_validation :normalize_code

  private

  def normalize_code
    self.code = code.to_s.parameterize(separator: "_") if code.present?
  end
end
