require 'test_helper'
require 'modules/stats/country.rb'


class StatsTest < ActiveSupport::TestCase
  test '.counts total number of protected areas' do
    FactoryGirl.create(:protected_area, :wdpa_id => 1)
    FactoryGirl.create(:protected_area, :wdpa_id => 2)
    assert_equal 2, Stats::Global.pa_count
  end

  test '.percentage cover of protected areas' do
    region = FactoryGirl.create(:region, iso: 'GLOBAL')
    FactoryGirl.create(:regional_statistic, region: region, :percentage_cover_pas => 50)
    assert_equal 50, Stats::Global.percentage_cover_pas
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

  test '.number of pas in one region' do
    region_1 = FactoryGirl.create(:region, name: 'Africasia', iso: 'AFS')
    region_2 = FactoryGirl.create(:region, name: 'Eurociania', iso: 'EOC')
    country_1 = FactoryGirl.create(:country, region: region_1)
    country_2 = FactoryGirl.create(:country, region: region_2)
    country_3 = FactoryGirl.create(:country, region: region_1)
    FactoryGirl.create(:protected_area, countries: [country_1], wdpa_id: 1)
    FactoryGirl.create(:protected_area, countries: [country_2], wdpa_id: 2)
    FactoryGirl.create(:protected_area, countries: [country_3], wdpa_id: 3)
    assert_equal 2, Stats::Regional.total_pas('AFS')
  end

  test '.percentage of global pas in one region' do
    region_1 = FactoryGirl.create(:region, name: 'Africasia', iso: 'AFS')
    region_2 = FactoryGirl.create(:region, name: 'Eurociania', iso: 'EOC')
    country_1 = FactoryGirl.create(:country, region: region_1)
    country_2 = FactoryGirl.create(:country, region: region_2)
    country_3 = FactoryGirl.create(:country, region: region_1)
    FactoryGirl.create(:protected_area, countries: [country_1], wdpa_id: 1)
    FactoryGirl.create(:protected_area, countries: [country_2], wdpa_id: 2)
    FactoryGirl.create(:protected_area, countries: [country_3], wdpa_id: 3)
    FactoryGirl.create(:protected_area, countries: [country_3], wdpa_id: 4)
    assert_equal 75, Stats::Regional.percentage_global_pas('AFS')
  end

  test '.percentage cover of protected areas in region' do
    region = FactoryGirl.create(:region, iso: 'BANANA')
    FactoryGirl.create(:regional_statistic, region: region, :percentage_cover_pas => 50)
    assert_equal 50, Stats::Regional.percentage_cover_pas('BANANA')
  end

  test '.protected areas with IUCN category per region' do
    iucn_category_1 = FactoryGirl.create(:iucn_category, name: 'Ib')
    iucn_category_2 = FactoryGirl.create(:iucn_category, name: 'V')
    no_iucn_category = FactoryGirl.create(:iucn_category, name: 'Pepe')
    region_1 = FactoryGirl.create(:region, name: 'Americasia', iso: 'AMA')
    region_2 = FactoryGirl.create(:region, name: 'Oceanafrica', iso: 'OAF')
    country_1 = FactoryGirl.create(:country, region: region_1)
    country_2 = FactoryGirl.create(:country, region: region_2)
    country_3 = FactoryGirl.create(:country, region: region_1)

    FactoryGirl.create(:protected_area, iucn_category: iucn_category_1, countries: [country_1] )
    FactoryGirl.create(:protected_area, iucn_category: iucn_category_2, countries: [country_2])
    FactoryGirl.create(:protected_area, iucn_category: no_iucn_category, countries: [country_2])
    FactoryGirl.create(:protected_area, iucn_category: iucn_category_2, countries: [country_3])
    assert_equal 2, Stats::Regional.pas_with_iucn_category('AMA')
  end

  test '.number of types of designations per region' do
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
    assert_equal 2, Stats::Regional.designation_count('AFE')
  end

  test '.total protected areas by designation in a region' do
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
    assert_equal ({'Cristiano Ronaldo' => 1, 'Lionel Messi' => 2}), Stats::Regional.protected_areas_by_designation('AFE')
  end

  test '.number of countries providing data by region' do
    region_1 = FactoryGirl.create(:region, name: 'Afronesia', iso: 'AFE')
    region_2 = FactoryGirl.create(:region, name: 'Eurarctica', iso: 'EUA')
    country_1 = FactoryGirl.create(:country, region: region_1)
    country_2 = FactoryGirl.create(:country, region: region_2)
    country_3 = FactoryGirl.create(:country, region: region_1)
    FactoryGirl.create(:protected_area, countries: [country_1], wdpa_id: 1)
    FactoryGirl.create(:protected_area, countries: [country_2], wdpa_id: 2)
    FactoryGirl.create(:protected_area, countries: [country_3], wdpa_id: 3)
    assert_equal 2, Stats::Regional.countries_providing_data('AFE')
  end


  test '.number of pas in one country' do
    country_1 = FactoryGirl.create(:country, name: 'Banana Republic', iso: 'BN')
    country_2 = FactoryGirl.create(:country, name: 'Kingdom of Pineapple', iso: 'KP')
    FactoryGirl.create(:protected_area, countries:  [country_1], wdpa_id: 1)
    FactoryGirl.create(:protected_area, countries: [country_1], wdpa_id: 2)
    FactoryGirl.create(:protected_area, countries: [country_2], wdpa_id: 3)
    assert_equal 2, Stats::Country.total_pas('BN')
  end

  test '.percentage of global pas in one country' do
    country_1 = FactoryGirl.create(:country, name: 'Banana Republic', iso: 'BN')
    country_2 = FactoryGirl.create(:country, name: 'Kingdom of Pineapple', iso: 'KP')
    FactoryGirl.create(:protected_area, countries:  [country_1], wdpa_id: 1)
    FactoryGirl.create(:protected_area, countries: [country_2], wdpa_id: 3)
    assert_equal 50, Stats::Country.percentage_global_pas('BN')
  end

  test '.percentage cover of protected areas in country' do
    country = FactoryGirl.create(:country, iso: 'BANANA')
    FactoryGirl.create(:country_statistic, country: country, :percentage_cover_pas => 50)
    assert_equal 50, Stats::Country.percentage_cover_pas('BANANA')
  end

  test '.protected areas with IUCN category per Country' do
    iucn_category_1 = FactoryGirl.create(:iucn_category, name: 'Ib')
    iucn_category_2 = FactoryGirl.create(:iucn_category, name: 'V')
    no_iucn_category = FactoryGirl.create(:iucn_category, name: 'Pepe')
    country_1 = FactoryGirl.create(:country, iso: 'TOMATO')
    country_2 = FactoryGirl.create(:country, iso: 'EGGPLANT')

    FactoryGirl.create(:protected_area, iucn_category: iucn_category_1, countries:  [country_1] )
    FactoryGirl.create(:protected_area, iucn_category: iucn_category_2, countries:  [country_2])
    FactoryGirl.create(:protected_area, iucn_category: no_iucn_category, countries:  [country_1])
    assert_equal 1, Stats::Country.pas_with_iucn_category('TOMATO')
  end

  test '.number of types of designations per country' do
    designation_1 = FactoryGirl.create(:designation, name: 'Lionel Messi')
    designation_2 = FactoryGirl.create(:designation, name: 'Robin Van Persie')
    designation_3 = FactoryGirl.create(:designation, name: 'Cristiano Ronaldo')
    country_1 = FactoryGirl.create(:country, iso: 'TOMATO')
    FactoryGirl.create(:protected_area, designation: designation_1, countries:  [country_1])
    FactoryGirl.create(:protected_area, designation: designation_2, countries:  [country_1])
    assert_equal 2, Stats::Country.designation_count('TOMATO')
  end

  test '.total protected areas by designation in a country' do
    designation_1 = FactoryGirl.create(:designation, name: 'Lionel Messi')
    designation_2 = FactoryGirl.create(:designation, name: 'Robin Van Persie')
    designation_3 = FactoryGirl.create(:designation, name: 'Cristiano Ronaldo')  
    country_1 = FactoryGirl.create(:country, iso: 'TOMATO')
    country_2 = FactoryGirl.create(:country, iso: 'BANANA')
    FactoryGirl.create(:protected_area, designation: designation_1, countries:  [country_1])
    FactoryGirl.create(:protected_area, designation: designation_1, countries:  [country_1])
    FactoryGirl.create(:protected_area, designation: designation_2, countries:  [country_1])
    FactoryGirl.create(:protected_area, designation: designation_3, countries:  [country_2])
    assert_equal ({'Lionel Messi' => 2, 'Robin Van Persie' => 1}), Stats::Country.protected_areas_by_designation('TOMATO')
  end




end