# Transient table — rows exist only for seats that are locked, booked, or blocked.
# No row = available. This keeps the table small and fast.
#
# Status transitions:
#   (no row)  → locked   : users begins checkout (bookings flow)
#   locked    → (no row) : lock expired or users abandoned (background job / release)
#   locked    → booked   : payment confirmed (bookings flow)
#   (no row)  → blocked  : admins manually holds a seat
#   blocked   → (no row) : admins unblocks
#   booked    → (no row) : ticket cancelled + refund completed (bookings flow)

class ShowSeatState < ApplicationRecord
  LOCK_DURATION = 5.minutes

  belongs_to :show
  belongs_to :seat
  belongs_to :locked_by_user, class_name: "User", optional: true

  enum :status, { locked: "locked", booked: "booked", blocked: "blocked" }, prefix: true

  before_validation :normalize_lock_metadata

  validates :show_id, :seat_id, :status, presence: true
  validates :seat_id, uniqueness: { scope: :show_id }
  validates :lock_token, :locked_until, :locked_by_user, presence: true, if: :status_locked?

  validate :seat_belongs_to_show_layout

  # Locks that have passed their expiry but haven't been cleaned up yet.
  scope :expired_locks, -> {
    where(status: "locked").where("locked_until < ?", Time.current)
  }
  scope :active_locks, -> {
    where(status: "locked").where("locked_until >= ?", Time.current)
  }
  scope :for_show, ->(show_or_id) {
    show_id = show_or_id.respond_to?(:id) ? show_or_id.id : show_or_id
    where(show_id: show_id)
  }

  def lock_expired?(reference_time = Time.current)
    status_locked? && locked_until.present? && locked_until < reference_time
  end

  def effective_status(reference_time = Time.current)
    return "available" if lock_expired?(reference_time)

    status
  end

  private

  def normalize_lock_metadata
    return if status_locked?

    self.lock_token = nil
    self.locked_until = nil
    self.locked_by_user = nil
  end

  def seat_belongs_to_show_layout
    return if show.blank? || seat.blank?
    unless seat.seat_layout_id == show.seat_layout_id
      errors.add(:seat, "does not belong to this show's layout")
    end
  end
end
