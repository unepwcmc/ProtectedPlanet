require 'test_helper'


class StatsTest < ActiveSupport::TestCase

  test '.counts total number of protected areas' do
    pa = ProtectedArea.create(wdpa_id: 1)
    pa = ProtectedArea.create(wdpa_id: 2)
    assert_equal 2, Stats.global_pa_count
  end
end