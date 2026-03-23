require 'test_helper'

class GreenListHelperTest < ActionView::TestCase
  include GreenListHelper

  test 'chart_row_pa_legend returns two legend entries with expected themes' do
    legends = chart_row_pa_legend

    assert_equal 2, legends.size
    assert_equal 'theme--aqua', legends.first[:theme]
    assert_equal 'theme--blue', legends.last[:theme]
  end
end

