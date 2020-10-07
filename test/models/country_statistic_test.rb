require 'test_helper'

class CountryStatisticTest < ActiveSupport::TestCase
  test '.top_marine_coverage scope returns statistics in correct order' do
    country_1 = FactoryGirl.create(:country, name: 'Italy')
    country_2 = FactoryGirl.create(:country, name: 'UK')
    country_3 = FactoryGirl.create(:country, name: 'Spain')

    country_stat_1 = FactoryGirl.create(:country_statistic, country: country_1, percentage_pa_marine_cover: 1.0)
    country_stat_2 = FactoryGirl.create(:country_statistic, country: country_2, percentage_pa_marine_cover: 3.0)
    country_stat_3 = FactoryGirl.create(:country_statistic, country: country_3, percentage_pa_marine_cover: nil)

    assert_equal CountryStatistic.top_marine_coverage, [country_stat_2, country_stat_1, country_stat_3]
  end

  test '.top_marine_coverage scope returns only 6 records' do
    7.times { FactoryGirl.create(:country_statistic) }

    assert_equal CountryStatistic.top_marine_coverage.count, 6
  end
end
