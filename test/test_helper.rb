require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

ActiveRecord::Migration.maintain_test_schema!

require 'mocha/test_unit'
require 'webmock/minitest'
WebMock.disable_net_connect!(:allow => "codeclimate.com")

Mocha::Configuration.prevent(:stubbing_non_existent_method)

class ActiveSupport::TestCase

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

  def sign_in user
    visit new_user_session_path
    within("#new_user") do
      fill_in 'Email', :with => user.email
      fill_in 'Password', :with => user.password
    end
    click_button 'Log in'
  end
end

# shut up, Sidekiq
Sidekiq.configure_client do |config|
  config.logger.level = Logger::WARN
end

