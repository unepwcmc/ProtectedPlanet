# require "codeclimate-test-reporter"
# CodeClimate::TestReporter.start
# require 'simplecov'
# require 'simplecov-console'
# SimpleCov.formatter = SimpleCov::Formatter::Console
# SimpleCov.start

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

ActiveRecord::Migration.maintain_test_schema!

require 'mocha/mini_test'
require 'webmock/minitest'
WebMock.disable_net_connect!(:allow => ["codeclimate.com"], :allow_localhost => true)

Mocha::Configuration.prevent(:stubbing_non_existent_method)

class ActionMailer::TestCase
  def html_body mail
    mail.body.parts.find{ |p| p.content_type.match(/html/) }.body.raw_source
  end
end

module MiniTest::Assertions
  def assert_same_elements(array_one, array_two)
    assert ((array_one - array_two) + (array_two - array_one)).empty?,
      "Expected #{array_one} to contain the same elements as #{array_two}"
  end
end

class ActionDispatch::IntegrationTest
  include Warden::Test::Helpers
  Warden.test_mode!

  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  Capybara.app = Rails.application

  def sign_in user
    login_as(user, scope: :user)
  end

  def teardown
    Warden.test_reset!
  end
end

class ActionController::TestCase
  include Devise::TestHelpers
end

# shut up, Sidekiq
Sidekiq.configure_client do |config|
  config.logger.level = Logger::WARN
end

Bystander.enable_testing!

def assert_greater(a, b)
    assert_operator a, :>, b
end
