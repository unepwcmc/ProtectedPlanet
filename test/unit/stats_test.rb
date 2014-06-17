require 'test_helper'


class StatsTest < ActiveSupport::TestCase

  test '.counts total number of protected areas' do
    FactoryGirl.create(:protected_area, :wdpa_id => 1)
    FactoryGirl.create(:protected_area, :wdpa_id => 2)
    assert_equal 2, Stats.global_pa_count
  end
end