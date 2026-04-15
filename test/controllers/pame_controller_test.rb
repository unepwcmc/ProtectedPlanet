require 'test_helper'

class PameControllerTest < ActionController::TestCase
  tests PameController

  def setup
    seed_cms
  end

  test 'index assigns table attributes, filters and initial json' do
    @controller.stubs(:render)

    get :index, params: { locale: 'en' }

    assert_response :success
    assert assigns(:table_attributes).present?
    assert assigns(:filters).present?
    assert assigns(:json).present?
    assert assigns(:tabs).present?
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

