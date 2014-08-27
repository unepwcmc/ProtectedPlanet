require 'test_helper'

class GlobalStatsTest < ActionDispatch::IntegrationTest
  def setup
    global_region = FactoryGirl.create(:region, iso: 'GL')
    FactoryGirl.create(:regional_statistic, region: global_region, pa_area: 100)
  end

  test 'renders the number of Protected Areas' do
    protected_area_count = 5
    protected_area_count.times do
      FactoryGirl.create(:protected_area)
    end

    get '/stats/global'

    assert_match(/#{protected_area_count}/, @response.body)
  end

  test 'renders the number of Protected Areas with IUCN Categories' do
    iucn_category = FactoryGirl.create(:iucn_category, name: 'Ia')
    pa_with_iucn_count = 5
    pa_with_iucn_count.times do
      FactoryGirl.create(:protected_area, iucn_category: iucn_category)
    end

    FactoryGirl.create(:protected_area)
    not_reported_iucn_category = FactoryGirl.create(:iucn_category, name: 'Not Reported')
    FactoryGirl.create(:protected_area, iucn_category: not_reported_iucn_category)

    get '/stats/global'

    assert_match(/#{pa_with_iucn_count}/, @response.body)
  end

  test 'renders the number of designations' do
    designation_count = 3
    designation_count.times do
      FactoryGirl.create(:designation)
    end

    get '/stats/global'

    assert_match(/#{designation_count}/, @response.body)
  end

  test 'renders the number of Countries providing data' do
    data_providing_country_count = 2
    data_providing_country_count.times do
      country = FactoryGirl.create(:country)
      FactoryGirl.create(:protected_area, countries: [country])
    end

    FactoryGirl.create(:country)

    get '/stats/global'

    assert_not_equal data_providing_country_count, Country.count
    assert_match(/#{data_providing_country_count}/, @response.body)
  end
end
