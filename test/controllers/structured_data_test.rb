# frozen_string_literal: true

require 'test_helper'

# The JSON-LD fallback in ApplicationController: what a page gets when it does not
# build its own @structured_data (CMS pages, search, error pages).
class HomeStructuredDataTest < ActionController::TestCase
  tests HomeController

  test 'the home page is the WebSite itself, identified by the bare domain' do
    seed_cms_home
    seed_global_statistics

    get :index

    data = @controller.structured_data
    assert_equal 'WebSite', data[:'@type']
    # NOT http://test.host/en -- default_url_options localises root_url.
    assert_equal 'http://test.host/', data[:url]
    assert_equal 'http://test.host/', data[:publisher][:url]
  end
end

class FallbackStructuredDataTest < ActionController::TestCase
  # Any controller that inherits the fallback and does not render is enough here:
  # the assertions are about the before_action-populated meta, not the view.
  tests GlobalStatisticsController

  def setup
    GlobalStatistic.stubs(:download_csv).returns("type,description,value\n")
    GlobalStatistic.stubs(:download_csv_filename).returns('global_statistics.csv')
  end

  test 'a non-home page is a WebPage at its own url, part of the WebSite' do
    get :download, params: { locale: 'en' }

    data = @controller.structured_data
    assert_equal 'WebPage', data[:'@type']
    assert_equal 'http://test.host/en/global_statistics_download', data[:url]
    assert_equal 'WebSite', data[:isPartOf][:'@type']
    assert_equal 'http://test.host/', data[:isPartOf][:url]
  end

  test 'a CMS page takes the name and description its meta tags render' do
    site = FactoryBot.create(:cms_site)
    layout = FactoryBot.create(:cms_layout, site: site)
    page = FactoryBot.create(:cms_page, site: site, layout: layout, label: 'Marine protected areas')
    # A page with no parent is the site root, and load_cms_content deliberately keeps
    # the site default title there -- this one has to look like a child page.
    page.stubs(:full_path).returns('/marine')
    page.fragments.create!(identifier: 'social_description', content: 'How much ocean is protected.')
    Comfy::Cms::Page.stubs(:find_by_full_path).returns(page)

    get :download

    data = @controller.structured_data
    assert_equal 'Marine protected areas', data[:name]
    assert_equal 'How much ocean is protected.', data[:description]
  end

  test 'a page with no meta of its own falls back to the site name and description' do
    get :download

    data = @controller.structured_data
    assert_equal I18n.t('meta.site.name'), data[:name]
    assert_equal I18n.t('meta.site.description'), data[:description]
  end
end
