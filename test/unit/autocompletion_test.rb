require 'test_helper'

class AutocompletionTest < ActiveSupport::TestCase
  test '.lookup, given a search term, returns an array of results' do
    term = 'san guill'
    expected_response = [{
      term: 'san guillermo',
      name: 'San Guillermo',
      type: 'protected_area',
      identifier: '1'
    }]

    $redis.stubs(:zrangebylex).returns(["san guillermo||San Guillermo||protected_area||1"])

    assert_same_elements expected_response, Autocompletion.lookup(term)
  end

  test '.populate saves all the items in the autocompletion redis key' do
    FactoryGirl.create(:protected_area, name: 'San Guillermo', wdpa_id: 123)
    FactoryGirl.create(:country, name: 'Japan', iso: 'JA')

    $redis.expects(:zadd).with('autocompletion', 0, "san guillermo||San Guillermo||protected_area||123")
    $redis.expects(:zadd).with('autocompletion', 0, "japan||Japan||country||JA")
    Autocompletion.populate
  end
end
