require 'test_helper'


class StatsTest < ActiveSupport::TestCase
  test '.counts total number of protected areas' do
    FactoryGirl.create(:protected_area, :wdpa_id => 1)
    FactoryGirl.create(:protected_area, :wdpa_id => 2)
    assert_equal 2, Stats.global_pa_count
  end

  test '.percentage cover of protected areas' do
    region = FactoryGirl.create(:region, name: 'global')
    FactoryGirl.create(:regional_statistic, region: region, :percentage_cover_pas => 50)
    assert_equal 50, Stats.global_percentage_cover_pas
  end

  test '.protected areas with IUCN category' do
    iucn_category_1 = FactoryGirl.create(:iucn_category, name: 'Ib')
    iucn_category_2 = FactoryGirl.create(:iucn_category, name: 'V')
    no_iucn_category = FactoryGirl.create(:iucn_category, name: 'Cristiano Ronaldo')

    FactoryGirl.create(:protected_area, iucn_category: iucn_category_1)
    FactoryGirl.create(:protected_area, iucn_category: iucn_category_2)
    FactoryGirl.create(:protected_area, iucn_category: no_iucn_category)
    assert_equal 2, Stats.global_pas_with_iucn_category
  end

  test '.number of types of designations' do
    FactoryGirl.create(:designation, name: 'Lionel Messi')
    FactoryGirl.create(:designation, name: 'Robin Van Persie')
    assert_equal 2, Stats.global_designation_count
  end

  test '.total protected areas by designation' do
    designation_1 = FactoryGirl.create(:designation, name: 'Lionel Messi')
    designation_2 = FactoryGirl.create(:designation, name: 'Robin Van Persie')
    FactoryGirl.create(:designation, name: 'Puppy')
    FactoryGirl.create(:protected_area, designation: designation_1, wdpa_id: 1)
    FactoryGirl.create(:protected_area, designation: designation_1, wdpa_id: 2)
    FactoryGirl.create(:protected_area, designation: designation_2, wdpa_id: 3)

    assert_equal ({'Lionel Messi' => 2, 'Robin Van Persie' => 1}), Stats.global_protected_areas_by_designation
  end




end