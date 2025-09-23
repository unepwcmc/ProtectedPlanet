# require "codeclimate-test-reporter"
# CodeClimate::TestReporter.start
# require 'simplecov'
# require 'simplecov-console'
# SimpleCov.formatter = SimpleCov::Formatter::Console
# SimpleCov.start

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'

ActiveRecord::Migration.maintain_test_schema!

require 'mocha/mini_test'
require 'webmock/minitest'

require 'database_cleaner'

WebMock.disable_net_connect!(allow: ['codeclimate.com'], allow_localhost: true)

# Configure DatabaseCleaner
DatabaseCleaner.strategy = :transaction
DatabaseCleaner.clean_with(:truncation)

Mocha::Configuration.prevent(:stubbing_non_existent_method)

class ActionMailer::TestCase
  def html_body(mail)
    mail.body.parts.find { |p| p.content_type.match(/html/) }.body.raw_source
  end
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

  def teardown; end
end

class ActionController::TestCase
end

class ActiveSupport::TestCase
  # Setup database cleaner
  setup do
    DatabaseCleaner.start
  end

  teardown do
    DatabaseCleaner.clean
  end

  # helper method to seed cms pages required for header/footer
  # any test that tries to render a view will need to call this first
  def seed_cms
    @site = FactoryGirl.create(:cms_site)
    @layout = FactoryGirl.create(:cms_layout, site: @site)
    FactoryGirl.create(:cms_page, site: @site, layout: @layout, slug: 'about')
    FactoryGirl.create(:cms_page, site: @site, layout: @layout, slug: 'news-and-stories')
    FactoryGirl.create(:cms_page, site: @site, layout: @layout, slug: 'resources')
    FactoryGirl.create(:cms_page, site: @site, layout: @layout, slug: 'monthly-release-news')
    FactoryGirl.create(:cms_page, site: @site, layout: @layout, slug: 'thematic-areas')
    # As of 07Apr2025 The oecms and wdpa don't seem to be needed
    FactoryGirl.create(:cms_page, site: @site, layout: @layout, slug: 'oecms')
    FactoryGirl.create(:cms_page, site: @site, layout: @layout, slug: 'wdpa')
    FactoryGirl.create(:cms_page, site: @site, layout: @layout, slug: 'legal')
  end

  # and home page needs some extra cms bits
  def seed_cms_home
    seed_cms
    # we need to add extra pages for pa categories on the home page
    FactoryGirl.create(:cms_page, site: @site, layout: @layout, slug: 'marine-protected-areas')
    FactoryGirl.create(:cms_page, site: @site, layout: @layout, slug: 'green-list')
    # and the CTAs
    FactoryGirl.create(:cms_cta, css_class: 'api')
    FactoryGirl.create(:cms_cta, css_class: 'live-report')
  end
end

# shut up, Sidekiq
Sidekiq.configure_client do |config|
  config.logger.level = Logger::WARN
end

Bystander.enable_testing!

def assert_greater(a, b)
  assert_operator a, :>, b
end
