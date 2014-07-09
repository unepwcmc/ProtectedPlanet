require 'test_helper'

class SitesTest < ActionDispatch::IntegrationTest
  test '/sites/:slug/* redirects to PA page' do
    wdpa_id = 1234

    protected_area = FactoryGirl.create(
      :protected_area, wdpa_id: wdpa_id, slug: 'slugger'
    )

    legacy_protected_area = FactoryGirl.create(
      :legacy_protected_area, wdpa_id: wdpa_id, slug: 'slug'
    )

    get "/sites/#{legacy_protected_area.slug}/hey_this_cant_possibly_exist"

    assert_redirected_to "/#{protected_area.slug}"
  end
end
