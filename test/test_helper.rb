# Coverage — opt-in via COVERAGE=1 so local `rake test` stays fast; CI sets it.
# Must start before any application code is required. The floor is a ratchet:
# CI fails if line coverage drops below it. Raise it as coverage improves;
# never lower it. Baseline was 54.6% on Rails 6.1 (Jul 2026); ratcheted to 62 on
# Rails 8 (Aug 2026, ~64.4% actual after the spatial/relation test net).
if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start 'rails' do
    add_filter '/test/'
    add_group 'Serializers', 'app/serializers'
    add_group 'Presenters', 'app/presenters'
    add_group 'Workers', 'app/workers'
    add_group 'lib/modules', 'lib/modules'
    minimum_coverage 62
  end
end

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

ActiveRecord::Migration.maintain_test_schema!

require 'mocha/minitest'
require 'webmock/minitest'

require 'database_cleaner'

WebMock.disable_net_connect!(:allow => ["codeclimate.com"], :allow_localhost => true)

# No test may announce itself in Slack. The release notifier posts to this webhook
# the moment it takes the release lock, and the dev container has a real one set, so
# any test that turns WebMock off (the ES ones must) would post to the team channel.
ENV.delete('PP_SLACK_WEBHOOK_URL')

Mocha.configure do |c|
  c.stubbing_non_existent_method = :prevent
  # Ruby 3 distinguishes positional hashes from keyword arguments; enforce the same in
  # Mocha's #with matching so expectations can't silently mismatch the real call.
  c.strict_keyword_argument_matching = true
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
  # The home page renders GlobalStatistic coverage percentages (HomePresenter
  # calls .round on them). The singleton row exists but its columns are nil until
  # seeded; in production they are always populated.
  def seed_global_statistics
    GlobalStatistic.instance.update!(
      total_land_pa_coverage_percentage: 12.0,
      total_ocean_pa_coverage_percentage: 8.0,
      total_land_oecms_pas_coverage_percentage: 1.0,
      total_ocean_oecms_pas_coverage_percentage: 2.0
    )
  end

  # Runs a block that reaps a real child process (Process.wait, or a real
  # `system` call) without leaving its exit status in `$?` for the rest of the
  # suite.
  #
  # `$?` is thread-local and starts out nil, so a test that genuinely waits on
  # a child leaves a status behind that the NEXT test inherits. Code that reads
  # `$?` after a stubbed `system` -- which never sets it -- then silently sees
  # the previous test's exit code instead of nil. Confining the real process
  # work to its own thread keeps `$?` where it belongs. Thread#value re-raises
  # in the caller, so assert_raises still works across the boundary.
  def without_leaking_child_status
    Thread.new do
      Thread.current.report_on_exception = false
      yield
    end.value
  end

  # ES indices outlive a test run: one a crashed run left behind makes create
  # fail with resource_already_exists. Always start from a clean index.
  def fresh_search_index index_name, collection
    index = Search::Index.new index_name, collection
    index.delete
    index.create
    index
  end

  # The portal importer resolves each row's country by ISO3 and drops the ones it
  # cannot match, so a run against an empty countries table imports nothing at all.
  # Loads the same CSVs db/seeds.rb does, without the CMS content that follows them
  # there. Tests are transactional, so the rows go away with the test.
  def seed_reference_data
    [Jurisdiction, Governance, IucnCategory, Region, Country].each do |model|
      next if model.exists?

      source = Rails.root.join('lib', 'data', 'seeds', "#{model.to_s.pluralize.underscore}.csv")
      CSV.foreach(source, headers: true) do |row|
        attributes = row.to_hash
        attributes['region_id'] = Region.find_by(name: attributes.delete('region'))&.id if model == Country
        model.create!(attributes)
      end
    end
  end

  # helper method to seed cms pages required for header/footer
  # any test that tries to render a view will need to call this first
  def seed_cms
    @site = FactoryBot.create(:cms_site)
    @layout = FactoryBot.create(:cms_layout, site: @site)
    FactoryBot.create(:cms_page, site: @site, layout: @layout, slug: PageSlugs::ABOUT)
    FactoryBot.create(:cms_page, site: @site, layout: @layout, slug: PageSlugs::NEWS_AND_STORIES)
    FactoryBot.create(:cms_page, site: @site, layout: @layout, slug: PageSlugs::RESOURCES)
    FactoryBot.create(:cms_page, site: @site, layout: @layout, slug: PageSlugs::MONTHLY_RELEASE_NEWS)
    FactoryBot.create(:cms_page, site: @site, layout: @layout, slug: PageSlugs::ThematicAreas::PARENT)
    FactoryBot.create(:cms_page, site: @site, layout: @layout, slug: PageSlugs::Data::PARENT)
    FactoryBot.create(:cms_page, site: @site, layout: @layout, slug: PageSlugs::Data::WDPCA)
    FactoryBot.create(:cms_page, site: @site, layout: @layout, slug: PageSlugs::LEGAL)
  end

  # and home page needs some extra cms bits
  def seed_cms_home
    seed_cms
    # we need to add extra pages for pa categories on the home page
    FactoryBot.create(:cms_page, site: @site, layout: @layout, slug: PageSlugs::ThematicAreas::MARINE)
    FactoryBot.create(:cms_page, site: @site, layout: @layout, slug: PageSlugs::ThematicAreas::EFFECTIVENESS)
    # and the CTAs
    FactoryBot.create(:cms_cta, css_class: PageSlugs::Cta::API)
    FactoryBot.create(:cms_cta, css_class: PageSlugs::Cta::PROTECTED_PLANET_REPORT)

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
