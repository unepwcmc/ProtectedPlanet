require 'test_helper'

class PameEvaluationFiltersTest < ActiveSupport::TestCase
  test 'filters_to_json includes site_type filter with Protected Area and OECM' do
    json = PameEvaluation.filters_to_json
    filters = JSON.parse(json)

    site_type_filter = filters.detect { |f| f['name'] == 'site_type' }
    refute_nil site_type_filter
    assert_equal ['Protected Area', 'OECM'], site_type_filter['options']
  end

  test 'parse_filters builds correct where for site_type Protected Area and OECM' do
    filters = [
      { 'name' => 'site_type', 'options' => ['OECM'] }
    ]
    where_params = PameEvaluation.parse_filters(filters)
    assert_equal 'protected_areas.is_oecm = true', where_params[:site_type]

    filters = [
      { 'name' => 'site_type', 'options' => ['Protected Area'] }
    ]
    where_params = PameEvaluation.parse_filters(filters)
    assert_equal '(protected_areas.is_oecm = false OR protected_areas.is_oecm IS NULL)', where_params[:site_type]
  end
end

