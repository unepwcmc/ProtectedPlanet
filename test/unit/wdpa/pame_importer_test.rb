require 'test_helper'

class TestPameImporter < ActiveSupport::TestCase
  test "#import pame evaluations" do

    PAME_EVALUATIONS = "#{Rails.root}/lib/data/seeds/test_pame_data.csv".freeze

    site_ids = [1,2,3]
    site_ids.each do |site_id|
      FactoryGirl.create(:protected_area, site_id: site_id)
    end

    arg = FactoryGirl.create(:country, iso_3: 'ARG', name: 'Argentina')
    
    Wdpa::PameImporter.import(PAME_EVALUATIONS)

    pame_evaluations = PameEvaluation.all
    assert_equal 9, pame_evaluations.count
    # make sure we don't create any new countries and that evaluation ends up attached to existing country
    assert_equal 1, Country.all.count
    assert_equal arg.id, pame_evaluations.first.countries[0].id
    # same for PAs don't create any more and should all be attached up
    assert_equal 3, ProtectedArea.all.count
    assert_equal 1, pame_evaluations.find(64).protected_area.site_id
    
  end

  test "#import pame evaluations with hidden evaluation" do
    PAME_EVALUATIONS = "#{Rails.root}/lib/data/seeds/test_pame_data_hidden.csv".freeze
    # this csv tests the three cases
    # nil pa not restricted, with pa with restricted and nil pa restricted.

    site_ids = [1,2,3]
    site_ids.each do |site_id|
      FactoryGirl.create(:protected_area, site_id: site_id)
    end

    Wdpa::PameImporter.import(PAME_EVALUATIONS)

    pame_evaluations = PameEvaluation.all
    assert_equal 9, pame_evaluations.count
    # check nil pa
    assert pame_evaluations.find(64).protected_area.nil?
    assert !pame_evaluations.find(64).restricted
    # pa and restricted
    assert_equal 2, pame_evaluations.find(66).protected_area.site_id
    assert pame_evaluations.find(66).restricted
    # nil pa and restricted
    assert pame_evaluations.find(70).protected_area.nil?
    assert pame_evaluations.find(70).restricted
  end
end
