class Ticket < ApplicationRecord
  belongs_to :booking
  belongs_to :show
  belongs_to :seat

  has_many :payment_refunds, dependent: :restrict_with_error

  enum :status, { valid: "valid", cancelled: "cancelled" }, prefix: true

  validates :seat_label, :section_name, :status, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validate :show_matches_booking
  validate :seat_belongs_to_show_layout
  validate :seat_not_already_reserved_for_show, if: :status_valid?

  private

  def show_matches_booking
    return if booking.blank? || show.blank?
    return if booking.show_id == show_id

    errors.add(:show, "must match the booking's show")
  end

  def seat_belongs_to_show_layout
    return if show.blank? || seat.blank?
    return if seat.seat_layout_id == show.seat_layout_id

    errors.add(:seat, "must belong to the show's seat layout")
  end

  def seat_not_already_reserved_for_show
    return if show_id.blank? || seat_id.blank?

    existing_ticket = self.class
      .where(show_id: show_id, seat_id: seat_id, status: "valid")
      .where.not(id: id)
      .exists?

    return unless existing_ticket

    errors.add(:seat_id, "has already been booked for this show")
  end
end
