# frozen_string_literal: true

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

# Run Coverage report
require "solidus_dev_support/rspec/coverage"

require File.expand_path("dummy/config/environment.rb", __dir__)

# Requires factories and other useful helpers defined in spree_core.
require "solidus_dev_support/rspec/feature_helper"

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |f| require f }

# Will load Solidus core factory first and then the ones
# defined in `lib/solidus_handling_fees/testing_support/factories`.
SolidusDevSupport::TestingSupport::Factories.load_for(SolidusHandlingFees::Engine)

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = false
end
