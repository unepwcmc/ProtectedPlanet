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

require 'mocha/minitest'
require 'webmock/minitest'

require 'database_cleaner'

WebMock.disable_net_connect!(:allow => ["codeclimate.com"], :allow_localhost => true)

Mocha.configure do |c|
  c.stubbing_non_existent_method = :prevent
end

class ActionMailer::TestCase
  def html_body mail
    mail.body.parts.find{ |p| p.content_type.match(/html/) }.body.raw_source
  end
end

module Minitest::Assertions
  def assert_same_elements(array_one, array_two)
    assert ((array_one - array_two) + (array_two - array_one)).empty?,
      "Expected #{array_one} to contain the same elements as #{array_two}"
  end
end

class ActionDispatch::IntegrationTest

  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  Capybara.app = Rails.application

  def teardown

  end
end

class ActionController::TestCase

end

class ActiveSupport::TestCase
  # helper method to seed cms pages required for header/footer
  # any test that tries to render a view will need to call this first
  def seed_cms
    @site = FactoryGirl.create(:cms_site)
    @layout = FactoryGirl.create(:cms_layout, site: @site)
    FactoryGirl.create(:cms_page, site: @site, layout: @layout, slug: PageSlugs::ABOUT)
    FactoryGirl.create(:cms_page, site: @site, layout: @layout, slug: PageSlugs::NEWS_AND_STORIES)
    FactoryGirl.create(:cms_page, site: @site, layout: @layout, slug: PageSlugs::RESOURCES)
    FactoryGirl.create(:cms_page, site: @site, layout: @layout, slug: PageSlugs::MONTHLY_RELEASE_NEWS)
    FactoryGirl.create(:cms_page, site: @site, layout: @layout, slug: PageSlugs::ThematicAreas::PARENT)
    FactoryGirl.create(:cms_page, site: @site, layout: @layout, slug: PageSlugs::Data::PARENT)
    FactoryGirl.create(:cms_page, site: @site, layout: @layout, slug: PageSlugs::Data::WDPCA)
    FactoryGirl.create(:cms_page, site: @site, layout: @layout, slug: PageSlugs::LEGAL)
  end

  # and home page needs some extra cms bits
  def seed_cms_home
    seed_cms
    # we need to add extra pages for pa categories on the home page
    FactoryGirl.create(:cms_page, site: @site, layout: @layout, slug: PageSlugs::ThematicAreas::MARINE)
    FactoryGirl.create(:cms_page, site: @site, layout: @layout, slug: PageSlugs::ThematicAreas::EFFECTIVENESS)
    # and the CTAs
    FactoryGirl.create(:cms_cta, css_class: PageSlugs::Cta::API)
    FactoryGirl.create(:cms_cta, css_class: PageSlugs::Cta::LIVE_REPORT)

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
