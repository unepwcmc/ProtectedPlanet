require 'test_helper'

class StatisticPresenterTest < ActiveSupport::TestCase
  # A country/PA without a statistic record must not 500 the page. geometry_ratio
  # previously called polygons_count on a nil @statistic (crashed country, search
  # and PA pages for any geo entity lacking a stat). Found in the Rails 7 smoke.
  test 'geometry_ratio returns zeros when the statistic is nil' do
    model = Object.new
    def model.statistic = nil
    def model.pame_statistic = nil

    presenter = StatisticPresenter.new(model)

    assert_equal({ polygons: 0, points: 0 }, presenter.geometry_ratio)
  end
end
