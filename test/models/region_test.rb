require 'test_helper'

class RegionTest < ActiveSupport::TestCase
  test '.bounds returns the bounds for all countries contained in the region' do
    region = FactoryGirl.create(:region, bounding_box: 'POLYGON ((-1 0, 0 1, 1 2, 1 0, -1 0))')

    assert_equal [[0, -1], [2, 1]], region.bounds
  end
end
