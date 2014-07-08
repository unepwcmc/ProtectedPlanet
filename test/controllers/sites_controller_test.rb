require 'test_helper'

class SitesControllerTest < ActionController::TestCase
  test 'GET :show redirects to the given legacy slug, if it exists' do
    wdpa_id = 5984
    slug = 'An_Old_PA'

    protected_area = FactoryGirl.create(:protected_area, wdpa_id: wdpa_id, slug: 'sluggity-slug')
    FactoryGirl.create(:legacy_protected_area, wdpa_id: wdpa_id, slug: slug)

    get :show, id: slug

    assert_redirected_to "/#{protected_area.slug}"
  end

  test 'GET :show redirects to the homepage if no match legacy PA
   exists' do
    get :show, id: 'slug'

    assert_redirected_to root_url
  end
end
