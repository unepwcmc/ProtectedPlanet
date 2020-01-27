require 'test_helper'

class SitesTest < ActionDispatch::IntegrationTest
  test '/sites/:slug/* redirects to PA page' do
    wdpa_id = 1234

    protected_area = FactoryGirl.create(
      :protected_area, wdpa_id: wdpa_id, slug: 'slugger'
    )

    get "/sites/#{wdpa_id}"

    assert_redirected_to protected_area_path(id: protected_area.slug)
  end
end
