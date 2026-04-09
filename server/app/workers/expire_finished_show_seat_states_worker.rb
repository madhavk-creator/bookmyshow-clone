class ExpireFinishedShowSeatStatesWorker
  include Sidekiq::Job

  sidekiq_options queue: :default

  def perform
    ExpireFinishedShowSeatStatesJob.perform_now
  end
end
