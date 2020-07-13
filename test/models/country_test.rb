require 'test_helper'

class CountryTest < ActiveSupport::TestCase
  test '.bounds returns the bounding box for the Country geometry' do
    country = FactoryGirl.create(:country, bounding_box: 'POLYGON ((-1 0, 0 1, 1 2, 1 0, -1 0))')

    assert_equal [[0, -1], [2, 1]], country.bounds
  end

  test '.without_geometry does not select the geometry columns' do
    country = FactoryGirl.create(:country)

    selected_country = Country.without_geometry.find(country.id)

    refute selected_country.has_attribute?(:bounding_box)
  end

  test '.as_indexed_json returns the Country as JSON' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, name: 'Manboneland', region: region)

    expected_json = {
      "id" => 123,
      "name" => 'Manboneland',
      "iso_3"=> 'MTX',
      "region_for_index" => {
        "name" => "North Manmerica"
      },
      "region_name" => "North Manmerica"
    }

    assert_equal expected_json, country.as_indexed_json
  end

  test '.protected_areas returns the number of Protected Areas in the country' do
    country = FactoryGirl.create(:country)

    expected_pas = [
      FactoryGirl.create(:protected_area, countries: [country]),
      FactoryGirl.create(:protected_area, countries: [country])
    ]

    FactoryGirl.create(:protected_area)

    protected_areas = country.protected_areas

    assert_equal 2, protected_areas.count
    assert_same_elements expected_pas.map(&:id), protected_areas.pluck(:id)
  end

  test ".designations returns the designations for the Country's Protected Areas" do
    designation_1 = FactoryGirl.create(:designation, name: 'Lionel Messi')
    designation_2 = FactoryGirl.create(:designation, name: 'Robin Van Persie')
    designation_3 = FactoryGirl.create(:designation, name: 'Cristiano Ronaldo')

    country_1 = FactoryGirl.create(:country)
    country_2 = FactoryGirl.create(:country)
    country_3 = FactoryGirl.create(:country)

    FactoryGirl.create(:protected_area, designation: designation_1, countries: [country_1])
    FactoryGirl.create(:protected_area, designation: designation_2, countries: [country_1])
    FactoryGirl.create(:protected_area, designation: designation_2, countries: [country_2])
    FactoryGirl.create(:protected_area, designation: designation_3, countries: [country_3])

    assert_equal 2, country_1.designations.count
  end

  test '.protected_areas_with_iucn_categories returns all Protected
   Areas with valid IUCN categories' do
    iucn_category_1 = FactoryGirl.create(:iucn_category, name: 'Ib')
    iucn_category_2 = FactoryGirl.create(:iucn_category, name: 'V')
    invalid_iucn_category = FactoryGirl.create(:iucn_category, name: 'Pepe')

    country_1 = FactoryGirl.create(:country)
    country_2 = FactoryGirl.create(:country)
    country_3 = FactoryGirl.create(:country)

    FactoryGirl.create(:protected_area, iucn_category: iucn_category_1, countries: [country_1] )
    FactoryGirl.create(:protected_area, iucn_category: iucn_category_2, countries: [country_1])
    FactoryGirl.create(:protected_area, iucn_category: invalid_iucn_category, countries: [country_2])
    FactoryGirl.create(:protected_area, iucn_category: iucn_category_2, countries: [country_3])

    assert_equal 2, country_1.protected_areas_with_iucn_categories.count
  end

  test '#data_providers returns all countries that provide PA data' do
    country_1 = FactoryGirl.create(:country)
    country_2 = FactoryGirl.create(:country)
    FactoryGirl.create(:country)

    FactoryGirl.create(:protected_area, countries: [country_1])
    FactoryGirl.create(:protected_area, countries: [country_2])

    assert_equal 2, Country.data_providers.count
  end

  test '#random_protected_areas, given an integer, returns the given number of random pas' do
    country = FactoryGirl.create(:country)
    country_pas = 2.times.map{ FactoryGirl.create(:protected_area, countries: [country]) }
    2.times{ FactoryGirl.create(:protected_area) }

    random_pas = country.random_protected_areas 2
    assert_same_elements country_pas, random_pas
  end

  test '#protected_areas_per_designation returns groups of pa counts per designation' do
    designation_1 = FactoryGirl.create(:designation)
    designation_2 = FactoryGirl.create(:designation)
    country = FactoryGirl.create(:country)
    expected_groups = [{
      'designation_id' => designation_1.id,
      'designation_name' => designation_1.name,
      'count' => 2
    }, {
      'designation_id' => designation_2.id,
      'designation_name' => designation_2.name,
      'count' => 3
    }]

    2.times { FactoryGirl.create(:protected_area, countries: [country], designation: designation_1) }
    3.times { FactoryGirl.create(:protected_area, countries: [country], designation: designation_2) }

    assert_same_elements expected_groups, country.protected_areas_per_designation.to_a
  end

  test '#protected_areas_per_iucn_category returns groups of pa counts per iucn_category' do
    iucn_category_1 = FactoryGirl.create(:iucn_category, name: 'Ib')
    iucn_category_2 = FactoryGirl.create(:iucn_category, name: 'V')
    country = FactoryGirl.create(:country)
    expected_groups = [{
      'iucn_category_id' => iucn_category_1.id,
      'iucn_category_name' => iucn_category_1.name,
      'count' => 2,
      'percentage' => '40.00'
    }, {
      'iucn_category_id' => iucn_category_2.id,
      'iucn_category_name' => iucn_category_2.name,
      'count' => 3,
      'percentage' => '60.00'
    }]

    2.times { FactoryGirl.create(:protected_area, countries: [country], iucn_category: iucn_category_1) }
    3.times { FactoryGirl.create(:protected_area, countries: [country], iucn_category: iucn_category_2) }

    assert_same_elements expected_groups, country.protected_areas_per_iucn_category.to_a
  end

  test '#protected_areas_per_governance returns groups of pa counts per governance' do
    governance_1 = FactoryGirl.create(:governance, name: 'Regional')
    governance_2 = FactoryGirl.create(:governance, name: 'International')
    country = FactoryGirl.create(:country)
    expected_groups = [{
      'governance_id' => governance_1.id,
      'governance_name' => governance_1.name,
      'governance_type' => nil,
      'count' => 2,
      'percentage' => '40.00'
    }, {
      'governance_id' => governance_2.id,
      'governance_name' => governance_2.name,
      'governance_type' => nil,
      'count' => 3,
      'percentage' => '60.00'
    }]

    2.times { FactoryGirl.create(:protected_area, countries: [country], governance: governance_1) }
    3.times { FactoryGirl.create(:protected_area, countries: [country], governance: governance_2) }

    assert_same_elements expected_groups, country.protected_areas_per_governance.to_a
  end
end
