class ExpireSeatLocksWorker
  include Sidekiq::Job

  sidekiq_options queue: :default

  def perform
    ExpireSeatLocksJob.perform_now
  end
end
