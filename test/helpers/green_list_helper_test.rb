require 'test_helper'

class GreenListHelperTest < ActionView::TestCase
  include GreenListHelper

  test 'total_coverage_chart_data returns total and coverage bars with expected legend colour classes' do
    chart_data = total_coverage_chart_data

    assert_equal 'tw-shared-chart-legend-colour-blue', chart_data[:total][:legend_colour_class]
    assert_equal 'tw-shared-chart-legend-colour-aqua', chart_data[:coverage][:legend_colour_class]
  end
end
