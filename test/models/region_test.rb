require 'test_helper'

class RegionTest < ActiveSupport::TestCase
  test '.bounds returns the bounds for all countries contained in the region' do
    region = FactoryGirl.create(:region, bounding_box: 'POLYGON ((-1 0, 0 1, 1 2, 1 0, -1 0))')

    assert_equal [[0, -1], [2, 1]], region.bounds
  end

  test '.protected_areas returns the number of Protected Areas in the region' do
    region = FactoryGirl.create(:region)
    country = FactoryGirl.create(:country, region: region)

    expected_pas = [
      FactoryGirl.create(:protected_area, countries: [country]),
      FactoryGirl.create(:protected_area, countries: [country])
    ]

    FactoryGirl.create(:protected_area)

    protected_areas = region.protected_areas

    assert_equal 2, protected_areas.count
    assert_same_elements expected_pas.map(&:id), protected_areas.pluck(:id)
  end

  test '.countries_providing_data returns all countries in the Region
   that have given Protected Area data' do
    afe_region = FactoryGirl.create(:region, name: 'Afronesia', iso: 'AFE')
    eua_region = FactoryGirl.create(:region, name: 'Eurarctica', iso: 'EUA')

    country_1 = FactoryGirl.create(:country, region: afe_region)
    country_2 = FactoryGirl.create(:country, region: eua_region)
    country_3 = FactoryGirl.create(:country, region: afe_region)

    FactoryGirl.create(:protected_area, countries: [country_1])
    FactoryGirl.create(:protected_area, countries: [country_2])
    FactoryGirl.create(:protected_area, countries: [country_3])

    assert_equal 2, afe_region.countries_providing_data.count
  end

  test ".designations returns the designations for the Region's Protected Areas" do
    designation_1 = FactoryGirl.create(:designation, name: 'Lionel Messi')
    designation_2 = FactoryGirl.create(:designation, name: 'Robin Van Persie')
    designation_3 = FactoryGirl.create(:designation, name: 'Cristiano Ronaldo')

    region_1 = FactoryGirl.create(:region, name: 'Afronesia', iso: 'AFE')
    region_2 = FactoryGirl.create(:region, name: 'Eurarctica', iso: 'EUA')

    country_1 = FactoryGirl.create(:country, region: region_1)
    country_2 = FactoryGirl.create(:country, region: region_2)
    country_3 = FactoryGirl.create(:country, region: region_1)

    FactoryGirl.create(:protected_area, designation: designation_1, countries: [country_1])
    FactoryGirl.create(:protected_area, designation: designation_1, countries: [country_1])
    FactoryGirl.create(:protected_area, designation: designation_2, countries: [country_2])
    FactoryGirl.create(:protected_area, designation: designation_3, countries: [country_3])

    assert_equal 2, region_1.designations.count
  end

  test '.protected_areas_with_iucn_categories returns all Protected
   Areas with valid IUCN categories' do
    iucn_category_1 = FactoryGirl.create(:iucn_category, name: 'Ib')
    iucn_category_2 = FactoryGirl.create(:iucn_category, name: 'V')
    invalid_iucn_category = FactoryGirl.create(:iucn_category, name: 'Pepe')

    region_1 = FactoryGirl.create(:region, name: 'Americasia', iso: 'AMA')
    region_2 = FactoryGirl.create(:region, name: 'Oceanafrica', iso: 'OAF')

    country_1 = FactoryGirl.create(:country, region: region_1)
    country_2 = FactoryGirl.create(:country, region: region_2)
    country_3 = FactoryGirl.create(:country, region: region_1)

    FactoryGirl.create(:protected_area, iucn_category: iucn_category_1, countries: [country_1] )
    FactoryGirl.create(:protected_area, iucn_category: iucn_category_2, countries: [country_2])
    FactoryGirl.create(:protected_area, iucn_category: invalid_iucn_category, countries: [country_2])
    FactoryGirl.create(:protected_area, iucn_category: iucn_category_2, countries: [country_3])

    assert_equal 2, region_1.protected_areas_with_iucn_categories.count
  end

  test '.without_geometry does not select the geometry columns' do
    region = FactoryGirl.create(:region)

    selected_region = Region.without_geometry.find(region.id)

    refute selected_region.has_attribute?(:bounding_box)
  end

  test '.as_indexed_json returns the region as JSON' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica', iso: 'NMM')

    expected_json = {
      "id" => 987,
      "name" => "North Manmerica",
      "iso" => 'NMM'
    }

    assert_equal expected_json, region.as_indexed_json
  end
end
