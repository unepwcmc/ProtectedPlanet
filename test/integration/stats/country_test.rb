require 'test_helper'

class CountryStatsTest < ActionDispatch::IntegrationTest
  def setup
    @region = FactoryGirl.create(:region)
    @regional_statistic = FactoryGirl.create(:regional_statistic, 
      region: @region, pa_area: 100)
    @country = FactoryGirl.create(:country, region: @region, iso: 'IT')
  end

  test 'renders the Country name' do
    FactoryGirl.create(:protected_area)
    FactoryGirl.create(:country_statistic, country: @country,
      pa_area: 40,
      percentage_pa_cover: 50,
      percentage_pa_land_cover: 50,
      percentage_pa_eez_cover: 50, percentage_pa_ts_cover: 50)
    get "/stats/country/#{@country.iso}"
    assert_match(/#{@country.name}/, @response.body)
  end

  test 'renders the number of PAs in the region' do
    pa_count = 2
    pa_count.times do
      FactoryGirl.create(:protected_area, countries: [@country], designation: nil)
    end
    FactoryGirl.create(:protected_area)
    FactoryGirl.create(:country_statistic, country: @country,
      percentage_pa_land_cover: 50,
      pa_area: 40,
      percentage_pa_eez_cover: 50, percentage_pa_ts_cover: 50)

    visit "/stats/country/#{@country.iso}"

    assert page.has_selector?('.pa-count'),
      "Expected page to have a PA count element"
    assert_equal 2, page.first('.pa-count p').text.to_i
  end

  test 'renders percentage of global pas in one country' do
    FactoryGirl.create(:protected_area, countries: [@country], designation: nil)
    FactoryGirl.create(:protected_area)
    FactoryGirl.create(:country_statistic, country: @country,
      percentage_pa_land_cover: 50, pa_area: 10,
      percentage_pa_eez_cover: 50, percentage_pa_ts_cover: 50)

    percentage = 10

    visit "/stats/country/#{@country.iso}"

    assert page.has_selector?('.pa-global-percentage'),
      "Expected page to have a PA percentage element"
    assert_equal percentage, page.find('.pa-global-percentage label .big').text.to_i
  end

  test 'renders the number of Protected Areas with IUCN Categories' do
    iucn_category = FactoryGirl.create(:iucn_category, name: 'Ia')

    pa_with_iucn_count = 2
    pa_with_iucn_count.times do
      FactoryGirl.create(:protected_area, countries: [@country], iucn_category: iucn_category)
    end

    FactoryGirl.create(:protected_area)
    not_reported_iucn_category = FactoryGirl.create(:iucn_category, name: 'Not Reported')
    FactoryGirl.create(:country_statistic, country: @country, 
      percentage_pa_land_cover: 50, pa_area: 40,
      percentage_pa_eez_cover: 50, percentage_pa_ts_cover: 50)
    FactoryGirl.create(:protected_area,
      iucn_category: not_reported_iucn_category, countries: [@country])

    visit "/stats/country/#{@country.iso}"

    assert page.has_selector?('.iucn-category-pa-count'),
      "Expected page to have an IUCN Category PA count element"
    assert_equal pa_with_iucn_count, page.first('.iucn-category-pa-count p').text.to_i
  end

  test 'renders the number of designations' do
    designation = FactoryGirl.create(:designation)
    FactoryGirl.create(:protected_area, designation: designation, countries: [@country])

    FactoryGirl.create(:country_statistic, country: @country,
      percentage_pa_land_cover: 50, pa_area: 40,
      percentage_pa_eez_cover: 50, percentage_pa_ts_cover: 50)

    FactoryGirl.create(:protected_area, designation: nil, countries: [@country])
    FactoryGirl.create(:protected_area)

    visit "/stats/country/#{@country.iso}"

    assert page.has_selector?('.designation-count'),
      "Expected page to have a designation count element"
    assert_equal 1, page.first('.designation-count p').text.to_i
  end

  test 'renders the designations by frequency' do
    designation_1 = FactoryGirl.create(:designation, name: 'Designation 1')
    FactoryGirl.create(:protected_area, designation: designation_1, countries: [@country])

    designation_2 = FactoryGirl.create(:designation, name: 'Designation 2')
    FactoryGirl.create(:protected_area, designation: designation_2, countries: [@country])

    FactoryGirl.create(:country_statistic, country: @country,
      percentage_pa_land_cover: 50, pa_area: 40,
      percentage_pa_eez_cover: 50, percentage_pa_ts_cover: 50)

    visit "/stats/country/#{@country.iso}"

    assert page.has_content?("Designations"),
      "Expected page to have a designation count element"
  end
end
