require "sidekiq"
require "sidekiq-cron"
require "erb"
require "yaml"

Sidekiq.configure_server do |config|
  config.on(:startup) do
    schedule_file = Rails.root.join("config/sidekiq_cron.yml")
    next unless schedule_file.exist?

    schedule = YAML.safe_load(
      ERB.new(schedule_file.read).result,
      aliases: true
    ) || {}

    Sidekiq::Cron::Job.load_from_hash(schedule)
  end
end
