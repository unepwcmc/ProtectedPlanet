require 'test_helper'

class RegionalStatsTest < ActionDispatch::IntegrationTest
  def setup
    @region = FactoryGirl.create(:region)
  end

  test 'renders the Region name' do
    get "/stats/regional/#{@region.iso}"
    assert_match(/#{@region.name}/, @response.body)
  end

  test 'renders the number of PAs in the region' do
    country = FactoryGirl.create(:country, region: @region)
    pa_count = 10
    pa_count.times do
      FactoryGirl.create(:protected_area, countries: [country], designation: nil)
    end
    FactoryGirl.create(:protected_area)

    visit "/stats/regional/#{@region.iso}"

    assert page.has_selector?('.pa-count'),
      "Expected page to have a PA count element"
    assert_equal pa_count, page.find('.pa-count p').text.to_i
  end

  test 'renders percentage of global pas in one regopm' do
    country = FactoryGirl.create(:country, region: @region)
    FactoryGirl.create(:protected_area, countries: [@country], designation: nil)
    FactoryGirl.create(:protected_area)
    percentage = 50

    visit "/stats/country/#{region.iso}"

    assert page.has_selector?('.pa-global-percentage'),
      "Expected page to have a PA percentage element"
    assert_equal percentage, page.find('.pa-global-percentage p').text.to_i
  end

  test 'renders the number of Protected Areas with IUCN Categories' do
    country = FactoryGirl.create(:country, region: @region)

    iucn_category = FactoryGirl.create(:iucn_category, name: 'Ia')
    pa_with_iucn_count = 5
    pa_with_iucn_count.times do
      FactoryGirl.create(:protected_area,
        iucn_category: iucn_category, designation: nil, countries: [country])
    end

    FactoryGirl.create(:protected_area)
    not_reported_iucn_category = FactoryGirl.create(:iucn_category, name: 'Not Reported')
    FactoryGirl.create(:protected_area, iucn_category: not_reported_iucn_category)

    visit "/stats/regional/#{@region.iso}"

    assert page.has_selector?('.iucn-category-pa-count'),
      "Expected page to have an IUCN Category PA count element"
    assert_equal pa_with_iucn_count, page.find('.iucn-category-pa-count p').text.to_i
  end

  test 'renders the number of designations' do
    regional_designation = FactoryGirl.create(:designation)
    non_regional_designation = FactoryGirl.create(:designation)

    country = FactoryGirl.create(:country, region: @region)
    FactoryGirl.create(:protected_area, countries: [country], designation: regional_designation)
    FactoryGirl.create(:protected_area, designation: non_regional_designation)

    visit "/stats/regional/#{@region.iso}"

    assert page.has_selector?('.designation-count'),
      "Expected page to have a designation count element"
    assert_equal "1", page.find('.designation-count p').text
  end

  test 'renders the number of Countries providing data' do
    data_providing_country_count = 5
    data_providing_country_count.times do
      country = FactoryGirl.create(:country, region: @region)
      FactoryGirl.create(:protected_area, countries: [country])
    end

    FactoryGirl.create(:country)

    visit "/stats/regional/#{@region.iso}"

    assert page.has_selector?('.country-count'),
      "Expected page to have a country count element"
    assert_equal data_providing_country_count, page.find('.country-count p').text.to_i
  end
end
