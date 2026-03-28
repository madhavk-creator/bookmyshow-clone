class ShowSeatState < ApplicationRecord
  belongs_to :show
  belongs_to :seat
  belongs_to :booking, optional: true
  belongs_to :locked_by_user, class_name: "User", optional: true

  enum :status, { locked: "locked", booked: "booked", blocked: "blocked" }, prefix: true

  validates :seat_id, uniqueness: { scope: :show_id }
  validates :status, presence: true
  validate :seat_belongs_to_show_layout
  validate :lock_fields_match_status

  scope :active_locks, -> { locked.where("locked_until > ?", Time.current) }

  private

  def seat_belongs_to_show_layout
    return if show.blank? || seat.blank?
    return if seat.seat_layout_id == show.seat_layout_id

    errors.add(:seat, "must belong to the show's seat layout")
  end

  def lock_fields_match_status
    case status
    when "locked"
      errors.add(:locked_by_user, "must be present when seat is locked") if locked_by_user.blank?
      errors.add(:locked_until, "must be present when seat is locked") if locked_until.blank?
    when "booked", "blocked"
      errors.add(:locked_until, "must be blank unless status is locked") if locked_until.present?
    end
  end
end
