class ShowSectionPrice < ApplicationRecord
  belongs_to :show
  belongs_to :seat_section

  validates :seat_section_id, uniqueness: { scope: :show_id }
  validates :base_price, numericality: { greater_than_or_equal_to: 0 }
  validate :section_belongs_to_show_layout

  private

  def section_belongs_to_show_layout
    return if show.blank? || seat_section.blank?
    return if seat_section.seat_layout_id == show.seat_layout_id

    errors.add(:seat_section, "must belong to the show's seat layout")
  end
end
