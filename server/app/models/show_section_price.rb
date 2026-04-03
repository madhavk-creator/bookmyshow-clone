class ShowSectionPrice < ApplicationRecord
  belongs_to :show
  belongs_to :seat_section

  validates :show_id, :seat_section_id, :base_price, presence: true
  validates :seat_section_id, uniqueness: { scope: :show_id }
  validates :base_price, numericality: { greater_than: 0 }

  validate :section_belongs_to_show_layout

  private

  def section_belongs_to_show_layout
    return if show.blank? || seat_section.blank?
    unless seat_section.seat_layout_id == show.seat_layout_id
      errors.add(:seat_section, "does not belong to this show's layout")
    end
  end
end
