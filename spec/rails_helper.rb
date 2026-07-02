# SimpleCov must start before the application code is loaded or nothing
# gets instrumented.
require "simplecov"
SimpleCov.start "rails" do
  enable_coverage :branch

  add_group "GraphQL", "app/graphql"
  add_group "Serializers", "app/serializers"
  add_group "Services", "app/services"

  # Coverage floor — fails the build when the FULL suite drops below it.
  # Skipped for targeted runs (e.g. `rspec spec/models/user_spec.rb`), which
  # would always read artificially low.
  minimum_coverage 90 if ARGV.grep(/spec/).empty?
end

require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"

Rails.root.glob("spec/support/**/*.rb").sort_by(&:to_s).each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [ Rails.root.join("spec/fixtures") ]
  config.use_transactional_fixtures = true
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods

  config.include GraphqlHelpers, type: :graphql

  # The presence registry is process-global; clear it between examples so liveness
  # state never leaks across tests.
  config.before { PresenceRegistry.reset! }

  # Bullet only detects N+1s inside a "request"; wrap each example so any spec
  # (GraphQL resolvers especially) fails loudly on an unbatched query pattern.
  config.around do |example|
    if defined?(Bullet) && Bullet.enable?
      Bullet.start_request
      example.run
      Bullet.perform_out_of_channel_notifications if Bullet.notification?
      Bullet.end_request
    else
      example.run
    end
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
