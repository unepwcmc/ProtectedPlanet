# frozen_string_literal: true

require 'test_helper'

class Thematic::EffectivenessControllerTest < ActionController::TestCase
  tests Thematic::EffectivenessController

  test 'index returns success' do
    @controller.stubs(:render)
    seed_cms
    GlobalStatistic.stubs(:green_list_stats).returns(
      'green_list_area' => 100.0,
      'green_list_perc' => 1.5,
      'green_list_count' => 10
    )
    get :index, params: { locale: 'en' }
    assert_response :success
  end

  test 'index assigns green list stats and filters' do
    @controller.stubs(:render)
    seed_cms
    GlobalStatistic.stubs(:green_list_stats).returns(
      'green_list_area' => 200.0,
      'green_list_perc' => 2.0,
      'green_list_count' => 20
    )
    get :index, params: { locale: 'en' }
    assert_equal 200.0, assigns(:greenlisted_pas_km)
    assert_equal 2.0, assigns(:greenlisted_pas_percent)
    assert_equal 20, assigns(:greenlisted_pas_total_count)
    assert_equal search_areas_path(
      filters: ::SearchAreaLinkFilters.green_list_status_filters
    ), assigns(:green_list_view_all_url)
  end
end
