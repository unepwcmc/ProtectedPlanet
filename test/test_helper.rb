ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha/test_unit'
require 'webmock/minitest'

class ActiveSupport::TestCase
  # Add more helper methods to be used by all tests here...
end

module MiniTest::Assertions
  def assert_same_elements(array_one, array_two)
    assert ((array_one - array_two) + (array_two - array_one)).empty?,
      "Expected #{array_one} to contain the same elements as #{array_two}"
  end
end

class ActionDispatch::IntegrationTest
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  Capybara.app = Rails.application
end

# shut up, Sidekiq
Sidekiq.configure_client do |config|
  config.logger.level = Logger::WARN
end
