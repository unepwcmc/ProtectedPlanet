require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  test "should get index" do
    seed_cms
    # we need to add extra pages for pa categories on the home page
    FactoryGirl.create(:cms_page, site: @site, layout: @layout, slug: 'marine-protected-areas')
    FactoryGirl.create(:cms_page, site: @site, layout: @layout, slug: 'green-list')
    # and the CTAs
    FactoryGirl.create(:cms_cta, css_class: 'api')
    FactoryGirl.create(:cms_cta, css_class: 'live-report')
    
    get :index
    assert_response :success
  end
end
