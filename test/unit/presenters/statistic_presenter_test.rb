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

    @statistic.stubs(:pa_area).returns(10)

    percentage = @presenter.percentage_of_global_pas
    assert_equal "40.0", percentage
  end

  test '.percentage_pa_marine_cover returns the total of marine cover' do
    @statistic.stubs(:percentage_pa_eez_cover).returns(30)
    @statistic.stubs(:percentage_pa_ts_cover).returns(23)

    percentage = @presenter.percentage_pa_marine_cover
    assert_equal "53.0", percentage
  end

  test '.marine_area returns the total marine area' do
    @statistic.stubs(:ts_area).returns(6)
    @statistic.stubs(:eez_area).returns(12)

    area = @presenter.marine_area
    assert_equal 18.0, area
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
end
