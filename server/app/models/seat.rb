class Seat < ApplicationRecord
  belongs_to :seat_layout
  belongs_to :seat_section
  has_many :show_seat_states, dependent: :restrict_with_error

  enum :seat_kind, {
    standard: "standard",
    recliner: "recliner",
    wheelchair: "wheelchair",
    companion: "companion",
    couple: "couple"
  }, prefix: true

  before_validation :normalize_row_label, :assign_label

  validates :row_label, :seat_number, :label, :grid_row, :grid_column, :seat_kind, presence: true
  validates :label, uniqueness: { scope: :seat_layout_id, case_sensitive: false }
  validates :seat_number, numericality: { only_integer: true, greater_than: 0 }
  validates :grid_row, :grid_column, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :x_span, :y_span, numericality: { only_integer: true, greater_than: 0 }
  validates :grid_column, uniqueness: { scope: [ :seat_layout_id, :grid_row ] }
  validate :section_belongs_to_layout

  private

  def normalize_row_label
    self.row_label = row_label.to_s.strip.upcase if row_label.present?
  end

  def assign_label
    return if row_label.blank? || seat_number.blank?

    self.label = "#{row_label}#{seat_number}"
  end

  def section_belongs_to_layout
    return if seat_section.blank? || seat_layout.blank?
    return if seat_section.seat_layout_id == seat_layout_id

    errors.add(:seat_section, "must belong to the same seat layout")
  end
end
