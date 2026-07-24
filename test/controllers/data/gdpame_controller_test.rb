require 'test_helper'

class Data::GdpameControllerTest < ActionController::TestCase
  tests Data::GdpameController

  def setup
    seed_cms
    # seed_cms creates the WDPCA data page but not GDPAME; without it @cms_page is
    # nil and the controller's tabs_list comes back empty.
    # @cms_page is resolved by Comfy full_path (/data/<slug>), which needs the page
    # nested under the data parent; seed_cms creates pages flat, so resolve it here.
    page = FactoryGirl.create(:cms_page, site: @site, layout: @layout, slug: PageSlugs::Data::GDPAME)
    Comfy::Cms::Page.stubs(:find_by_full_path).returns(page)
    # tabs_list is built from tab-title-N / tab-content-N CMS fragments on the page.
    page.fragments.create!(identifier: 'tab-title-1', content: 'Overview')
  end

  test 'index assigns table attributes, filters and initial json' do
    @controller.stubs(:render)

    get :index, params: { locale: 'en' }

    assert_response :success
    assert assigns(:table_attributes).present?
    assert assigns(:filters).present?
    assert assigns(:json).present?
    assert assigns(:tabs_list).present?
  end

  test 'list returns paginated evaluations as json' do
    paginated = {
      current_page: 2,
      per_page: 50,
      total_entries: 10,
      total_pages: 1,
      items: [{ id: 1 }]
    }
    PameEvaluation.expects(:paginate_evaluations).with(includes('"requested_page"')).returns(paginated)

    post :list, params: { locale: 'en', requested_page: 2, filters: [] }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 2, body['current_page']
    assert_equal 1, body['items'].first['id']
  end
end
