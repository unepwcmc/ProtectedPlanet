require 'test_helper'

class TestPameImporter < ActiveSupport::TestCase
  test "#import pame evaluations" do

    PAME_EVALUATIONS = "#{Rails.root}/lib/data/seeds/test_pame_data.csv".freeze

    wdpa_ids = [1,2,3]
    wdpa_ids.each do |wdpa_id|
      FactoryGirl.create(:protected_area, wdpa_id: wdpa_id)
    end

    Wdpa::PameImporter.import(PAME_EVALUATIONS)

    pame_evaluations = PameEvaluation.all
    assert_equal 9, pame_evaluations.count
  end

  test "#import pame evaluations with hidden evaluation" do

    PAME_EVALUATIONS = "#{Rails.root}/lib/data/seeds/test_pame_data_hidden.csv".freeze
    # this csv tests the three cases
    # nil pa not restricted, with pa with restricted and nil pa restricted.

    wdpa_ids = [1,2,3]
    wdpa_ids.each do |wdpa_id|
      FactoryGirl.create(:protected_area, wdpa_id: wdpa_id)
    end

    Wdpa::PameImporter.import(PAME_EVALUATIONS)

    pame_evaluations = PameEvaluation.all
    assert_equal 9, pame_evaluations.count
  end
end