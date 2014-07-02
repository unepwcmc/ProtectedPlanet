require 'test_helper'

class CountryStatsTest < ActionDispatch::IntegrationTest
  def setup
    region = FactoryGirl.create(:region)
    @country = FactoryGirl.create(:country, region: region)
  end

  test 'renders the Country name' do
    get "/stats/country/#{@country.iso}"
    assert_match(/#{@country.name}/, @response.body)
  end

  test 'renders the number of PAs in the region' do
    pa_count = 10
    pa_count.times do
      FactoryGirl.create(:protected_area, countries: [@country], designation: nil)
    end
    FactoryGirl.create(:protected_area)

    visit "/stats/country/#{@country.iso}"

    assert page.has_selector?('.pa-count'),
      "Expected page to have a PA count element"
    assert_equal pa_count, page.find('.pa-count p').text.to_i
  end

  test 'renders the number of Protected Areas with IUCN Categories' do
    iucn_category = FactoryGirl.create(:iucn_category, name: 'Ia')

    pa_with_iucn_count = 5
    pa_with_iucn_count.times do
      FactoryGirl.create(:protected_area, countries: [@country], iucn_category: iucn_category)
    end

    FactoryGirl.create(:protected_area)
    not_reported_iucn_category = FactoryGirl.create(:iucn_category, name: 'Not Reported')
    FactoryGirl.create(:protected_area,
      iucn_category: not_reported_iucn_category, countries: [@country])

    visit "/stats/country/#{@country.iso}"

    assert page.has_selector?('.iucn-category-pa-count'),
      "Expected page to have an IUCN Category PA count element"
    assert_equal pa_with_iucn_count, page.find('.iucn-category-pa-count p').text.to_i
  end

  test 'renders the number of designations' do
    designation_count = 3
    designation_count.times do
      designation = FactoryGirl.create(:designation)
      FactoryGirl.create(:protected_area, designation: designation, countries: [@country])
    end

    FactoryGirl.create(:protected_area, designation: nil, countries: [@country])
    FactoryGirl.create(:protected_area)

    visit "/stats/country/#{@country.iso}"

    assert page.has_selector?('.designation-count'),
      "Expected page to have a designation count element"
    assert_equal designation_count, page.find('.designation-count p').text.to_i
  end

  test 'renders the designations by frequency' do
    designation_1 = FactoryGirl.create(:designation, name: 'Designation 1')
    FactoryGirl.create(:protected_area, designation: designation_1, countries: [@country])

    designation_2 = FactoryGirl.create(:designation, name: 'Designation 2')
    FactoryGirl.create(:protected_area, designation: designation_2, countries: [@country])

    visit "/stats/country/#{@country.iso}"

    assert page.has_selector?('.designation-frequency'),
      "Expected page to have a designation count element"

    assert_equal 2, page.all('.designation-frequency li').count,
      "Expected to have a list element per designation"

    assert_equal "Designation 1 (1)",
      page.all('.designation-frequency li').first.text
    assert_equal "Designation 2 (1)",
      page.all('.designation-frequency li').last.text
  end
end
