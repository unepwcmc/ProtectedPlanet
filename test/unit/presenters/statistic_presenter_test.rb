require 'test_helper'

class StatisticPresenterTest < ActiveSupport::TestCase
  def setup
    @statistic = FactoryGirl.create(:country_statistic)
    @country = FactoryGirl.create(:country, country_statistic: @statistic)

    @presenter = StatisticPresenter.new @country
  end

  test '.percentage_of_global_pas returns the percentage of global PAs' do
    global_statistic = FactoryGirl.create(:regional_statistic, pa_area: 25)
    FactoryGirl.create(:region, iso: 'GL', regional_statistic: global_statistic)
    Region.where(iso: 'GL').first.regional_statistic = global_statistic

    @statistic.stubs(:pa_area).returns(10)

    percentage = @presenter.percentage_of_global_pas
    assert_equal "40.0", percentage
  end

  test '.percentage_of_global_pas returns 0 if the percentage cannot
   be calculated' do
    percentage = @presenter.percentage_of_global_pas
    assert_equal "0", percentage
  end

  test '.percentage_pa_cover returns the percentage pa cover' do
    CountryStatistic.any_instance.stubs(:percentage_pa_cover).returns(50)
    percentage = @presenter.percentage_pa_cover
    assert_equal 50, percentage
  end

  test 'model methods are passed through to the initial model' do
    Country.any_instance.expects(:designations)
    @presenter.designations
  end

  test 'percentage total pa cover correctly calculated based on areas' do
    CountryStatistic.any_instance.stubs(:pa_land_area).returns(50)
    CountryStatistic.any_instance.stubs(:land_area).returns(100)

    CountryStatistic.any_instance.stubs(:pa_marine_area).returns(50)
    CountryStatistic.any_instance.stubs(:marine_area).returns(100)
    assert_equal 50, @presenter.percentage_total_pa_cover
  end

  test 'percentage total pa cover upper-bounded by 100' do
    CountryStatistic.any_instance.stubs(:pa_land_area).returns(50)
    CountryStatistic.any_instance.stubs(:land_area).returns(50)

    CountryStatistic.any_instance.stubs(:pa_marine_area).returns(110)
    CountryStatistic.any_instance.stubs(:marine_area).returns(100)
    assert_equal 100, @presenter.percentage_total_pa_cover
  end

  test 'percentage total pa cover can cope even when country has no area' do
    CountryStatistic.any_instance.stubs(:pa_land_area).returns(50)
    CountryStatistic.any_instance.stubs(:land_area).returns(0)

    CountryStatistic.any_instance.stubs(:pa_marine_area).returns(50)
    CountryStatistic.any_instance.stubs(:marine_area).returns(0)
    assert_equal 100, @presenter.percentage_total_pa_cover
  end

end
