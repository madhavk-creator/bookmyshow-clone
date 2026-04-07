require_relative "spec_helper"

ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "factory_bot"
require "trailblazer/operation"
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |file| require file }
FactoryBot.definition_file_paths = [ Rails.root.join("spec/factories").to_s ]
FactoryBot.find_definitions

abort("The Rails environment is running in production mode!") if Rails.env.production?

def truncate_test_tables!
  connection = ActiveRecord::Base.connection
  tables = connection.tables - %w[schema_migrations ar_internal_metadata]

  connection.disable_referential_integrity do
    tables.each do |table|
      connection.execute("TRUNCATE TABLE #{connection.quote_table_name(table)} RESTART IDENTITY CASCADE")
    end
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    ActiveRecord::Migration.maintain_test_schema!
    truncate_test_tables!
  end

  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end

  config.include FactoryBot::Syntax::Methods
end
