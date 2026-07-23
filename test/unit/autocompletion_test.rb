require 'test_helper'

class AutocompletionTest < ActiveSupport::TestCase
  test '.lookup, given a search term, returns an array of results' do
    term = 'san guill'

    pa = FactoryGirl.create(:protected_area, site_id: 46, name: 'San Guillermo')

    # Autocompletion.lookup now returns the full result shape (see lib/modules/autocompletion.rb).
    expected_response = [{
      id: pa.site_id,
      is_pa: true,
      extent_url: pa.extent_url,
      title: 'San Guillermo',
      url: "/#{pa.site_id}"
    }]

    search_results = {
      'hits' => {
        'hits' => [{
          '_index' => Search::PA_INDEX,
          '_source' => {
            'id' => pa.id
          }
        }, {
          '_index' => Search::COUNTRY_INDEX,
          '_source' => {}
        }]
      }
    }

    search_mock = mock
    search_mock
      .expects(:search)
      .returns(search_results)
    Elasticsearch::Client.stubs(:new).returns(search_mock)

    #    $redis.stubs(:zrangebylex).returns(["san guillermo||San Guillermo||protected_area||1"])

    assert_same_elements expected_response, Autocompletion.lookup(term)
  end
end
