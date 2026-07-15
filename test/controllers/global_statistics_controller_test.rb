# frozen_string_literal: true

require 'test_helper'

class GlobalStatisticsControllerTest < ActionController::TestCase
  tests GlobalStatisticsController

  test 'download serves the generated csv as an attachment' do
    GlobalStatistic.stubs(:download_csv).returns("type,description,value\n")
    GlobalStatistic.stubs(:download_csv_filename).returns('global_statistics_2026-07-01.csv')

    get :download

    assert_response :success
    assert_equal 'text/csv', @response.media_type
    assert_match(/attachment/, @response.headers['Content-Disposition'])
    assert_match(/global_statistics_2026-07-01\.csv/, @response.headers['Content-Disposition'])
    assert_equal "type,description,value\n", @response.body
  end
end
