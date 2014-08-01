require 'test_helper'

class StatsTest < ActiveSupport::TestCase
  test '.counts total number of protected areas' do
    FactoryGirl.create(:protected_area, :wdpa_id => 1)
    FactoryGirl.create(:protected_area, :wdpa_id => 2)
    assert_equal 2, Stats::Global.pa_count
  end

  test '.percentage cover of protected areas' do
    region = FactoryGirl.create(:region, iso: 'GLOBAL')
    FactoryGirl.create(:regional_statistic, region: region, :percentage_pa_cover => 50)
    assert_equal 50, Stats::Global.percentage_pa_cover
  end

  test '.protected areas with IUCN category' do
    iucn_category_1 = FactoryGirl.create(:iucn_category, name: 'Ib')
    iucn_category_2 = FactoryGirl.create(:iucn_category, name: 'V')
    no_iucn_category = FactoryGirl.create(:iucn_category, name: 'Cristiano Ronaldo')

    FactoryGirl.create(:protected_area, iucn_category: iucn_category_1)
    FactoryGirl.create(:protected_area, iucn_category: iucn_category_2)
    FactoryGirl.create(:protected_area, iucn_category: no_iucn_category)
    assert_equal 2, Stats::Global.pas_with_iucn_category
  end

  test '.number of types of designations' do
    FactoryGirl.create(:designation, name: 'Lionel Messi')
    FactoryGirl.create(:designation, name: 'Robin Van Persie')
    assert_equal 2, Stats::Global.designation_count
  end

  test '.total protected areas by designation' do
    designation_1 = FactoryGirl.create(:designation, name: 'Lionel Messi')
    designation_2 = FactoryGirl.create(:designation, name: 'Robin Van Persie')
    FactoryGirl.create(:protected_area, designation: designation_1, wdpa_id: 1)
    FactoryGirl.create(:protected_area, designation: designation_1, wdpa_id: 2)
    FactoryGirl.create(:protected_area, designation: designation_2, wdpa_id: 3)
    assert_equal ({'Lionel Messi' => 2, 'Robin Van Persie' => 1}), Stats::Global.protected_areas_by_designation
  end

  test '.number of countries providing data' do
    country_1 = FactoryGirl.create(:country, name: 'Old Caledonia')
    country_2 = FactoryGirl.create(:country, name: 'Old Zealand')
    FactoryGirl.create(:protected_area, countries: [country_1], wdpa_id: 1)
    FactoryGirl.create(:protected_area, countries: [country_1], wdpa_id: 2)
    FactoryGirl.create(:protected_area, countries: [country_2], wdpa_id: 3)
    assert_equal 2, Stats::Global.countries_providing_data
  end
end
