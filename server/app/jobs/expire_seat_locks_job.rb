# Job to expire seat locks:
#   1. Finds all ShowSeatState rows with status=locked and locked_until < now
#   2. Groups them by lock_token to identify abandoned bookings
#   3. Deletes the lock rows (seat becomes available again)
#   4. Marks the associated pending booking as expired

class ExpireSeatLocksJob < ApplicationJob
  queue_as :default

  def perform
    expired = ShowSeatState.expired_locks.includes(:show)
    return if expired.none?

    # Group by lock_token to find associated bookings
    lock_tokens = expired.pluck(:lock_token).uniq.compact

    ActiveRecord::Base.transaction do
      # Release the expired locks first
      expired.delete_all

      # Expire any pending bookings that held these locks
      # Booking stores lock_token so we can correlate directly
      if lock_tokens.any?
        Booking.where(lock_token: lock_tokens, status: 'pending').update_all(status: 'expired')
      end
    end
  end
end
