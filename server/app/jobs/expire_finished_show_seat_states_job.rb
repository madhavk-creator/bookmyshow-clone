# Job to clean up transient seat state once a show has finished:
#   1. Finds non-cancelled shows whose end_time has passed
#   2. Deletes all related show_seat_state rows
#   3. Marks any still-scheduled shows as completed

class ExpireFinishedShowSeatStatesJob < ApplicationJob
  queue_as :default

  def perform
    Show.sync_finished_statuses!

    finished_show_ids = Show.finished.where.not(status: "cancelled").pluck(:id)
    return if finished_show_ids.empty?

    ActiveRecord::Base.transaction do
      ShowSeatState.where(show_id: finished_show_ids).delete_all
    end
  end
end
