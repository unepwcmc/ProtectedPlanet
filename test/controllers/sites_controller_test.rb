require 'test_helper'

class SitesControllerTest < ActionController::TestCase
  test 'GET :show redirects to the given slug, if it exists' do
    wdpa_id = 5984

    protected_area = FactoryGirl.create(:protected_area, wdpa_id: wdpa_id, slug: 'sluggity-slug')

    get :show, params: {id: wdpa_id}

    assert_redirected_to protected_area_path(id: protected_area.slug)
  end

  test 'GET :show redirects to the homepage if no match legacy PA
   exists' do
    get :show, params: {id: 'slug'}

    assert_redirected_to root_url
  end
end
