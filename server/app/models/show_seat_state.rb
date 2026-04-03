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
  belongs_to :locked_by_user, class_name: 'User', optional: true

  enum :status, { locked: 'locked', booked: 'booked', blocked: 'blocked' }, prefix: true

  validates :show_id, :seat_id, :status, presence: true
  validates :seat_id, uniqueness: { scope: :show_id }

  validate :seat_belongs_to_show_layout
  validate :lock_token_present_when_locked

  # Locks that have passed their expiry but haven't been cleaned up yet.
  scope :expired_locks, -> {
    where(status: 'locked').where('locked_until < ?', Time.current)
  }

  def effective_status
    return 'available' if status_locked? && locked_until.present? && locked_until < Time.current

    status
  end

  private

  def seat_belongs_to_show_layout
    return if show.blank? || seat.blank?
    unless seat.seat_layout_id == show.seat_layout_id
      errors.add(:seat, "does not belong to this show's layout")
    end
  end

  def lock_token_present_when_locked
    if status_locked? && lock_token.blank?
      errors.add(:lock_token, 'must be present for locked seats')
    end
  end
end
