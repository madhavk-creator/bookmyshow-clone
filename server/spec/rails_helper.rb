require_relative "spec_helper"

ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "trailblazer/operation"
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |file| require file }

abort("The Rails environment is running in production mode!") if Rails.env.production?

RSpec.configure do |config|
  config.before(:suite) do
    ActiveRecord::Migration.maintain_test_schema!
  end
end
