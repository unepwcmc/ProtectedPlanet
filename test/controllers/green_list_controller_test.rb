# frozen_string_literal: true

require 'test_helper'

class GreenListControllerTest < ActionController::TestCase
  tests GreenListController

  test 'index returns success' do
    seed_cms_home
    GlobalStatistic.stubs(:green_list_stats).returns(
      'green_list_area' => 100.0,
      'green_list_perc' => 1.5,
      'green_list_count' => 10
    )
    get :index, params: { locale: 'en' }
    assert_response :success
  end

  test 'index assigns green list stats and filters' do
    seed_cms_home
    GlobalStatistic.stubs(:green_list_stats).returns(
      'green_list_area' => 200.0,
      'green_list_perc' => 2.0,
      'green_list_count' => 20
    )
    get :index, params: { locale: 'en' }
    assert_equal 200.0, assigns(:pas_km)
    assert_equal 2.0, assigns(:pas_percent)
    assert_equal 20, assigns(:pas_total)
    assert_equal %w[pa_or_any_its_parcels_is_greenlisted pa_or_any_its_parcels_is_greenlist_candidate], assigns(:filters)[:special_status]
  end
end
