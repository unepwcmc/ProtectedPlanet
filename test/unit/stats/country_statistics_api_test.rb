require 'test_helper'

class TestCountryStatisticsApi < ActiveSupport::TestCase

  def setup
    @country_ita = FactoryGirl.create(:country, iso_3: 'ITA')
    @country_statistic_ita = FactoryGirl.create(:country_statistic, country_id: @country_ita.id)
    @country_esp = FactoryGirl.create(:country, iso_3: 'ESP')
    @country_statistic_esp = FactoryGirl.create(:country_statistic, country_id: @country_esp.id)
    @singleton_class = Stats::CountryStatisticsApi.singleton_class
    @iso3_attr = @singleton_class::ISO3_ATTRIBUTE
  end

  test 'import populates country statistics records' do
    importance_attr = @singleton_class::STATISTICS_API['importance_attribute']
    data = [
      {
        "#{@iso3_attr}" => 'ITA',
        "#{importance_attr}" => 12.15
      },
      {
        "#{@iso3_attr}" => 'ESP',
        "#{importance_attr}" => 11
      }
    ]
    Stats::CountryStatisticsApi.expects(:fetch_national_data).returns(data)

    Stats::CountryStatisticsApi.import

    assert_equal @country_statistic_ita.reload.percentage_importance, 12.15
    assert_equal @country_statistic_esp.reload.percentage_importance, 11
  end

  test 'import with iso parameter populates only country statistics record related to parameter' do
    well_connected_attr = @singleton_class::STATISTICS_API['well_connected_attribute']
    country_iso = 'ITA'
    data = [
      {
        "#{@iso3_attr}" => country_iso,
        "#{well_connected_attr}" => 12.15
      }
    ]
    Stats::CountryStatisticsApi.expects(:fetch_national_data).with(country_iso).returns(data)

    Stats::CountryStatisticsApi.import(country_iso)

    assert_equal @country_statistic_ita.reload.percentage_well_connected, 12.15
    assert_nil @country_statistic_esp.reload.percentage_well_connected
  end

  test 'import fetches and saves country area from API' do
    country_area_attr = @singleton_class::COUNTRY_AREA_ATTRIBUTE
    country_iso = 'ESP'
    data = [
      {
        "#{@iso3_attr}" => country_iso,
        "#{country_area_attr}" => 123.45
      }
    ]
    Stats::CountryStatisticsApi.expects(:fetch_national_data).with(country_iso).returns(data)

    Stats::CountryStatisticsApi.import(country_iso)

    assert_equal @country_statistic_esp.reload.jrc_country_area, 123.45
  end

  test 'import logs not found country when fetched iso code does not exist in the db' do
    well_connected_attr = @singleton_class::STATISTICS_API['well_connected_attribute']
    country_iso = 'FRA'
    data = [
      {
        "#{@iso3_attr}" => country_iso,
        "#{well_connected_attr}" => 12.15
      }
    ]
    Stats::CountryStatisticsApi.expects(:fetch_national_data).returns(data)
    Stats::CountryStatisticsApi.expects(:log_not_found_objects).
      with('country', [country_iso])
    Stats::CountryStatisticsApi.expects(:log_not_found_objects).
      with('statistic', [])

    Stats::CountryStatisticsApi.import
  end
end
