require 'test_helper'

class ProtectedAreasHelperTest < ActionView::TestCase
  test '#map_bounds, given a ProtectedArea object, returns a hash containing
   its bounds' do
    pa = FactoryGirl.create(:protected_area)

    pa.expects(:bounds).twice.returns([[0,0], [1,1]])

    assert_equal map_bounds(pa), {'from' => [0,0], 'to' => [1,1]}
  end

  test '#map_bounds, given no arguments, returns a hash containing
   the default bounds' do
    Rails.application.secrets.default_map_bounds = {'from' =>  [1,1], 'to' => [1,2]}

    assert_equal map_bounds, {'from' => [1,1], 'to' => [1,2]}
  end
end
