require 'test_helper'

class SearchAggregatorsBooleanTest < ActiveSupport::TestCase
  test '.build, given a name, raw aggregations, and a configuration hash,
   returns the computed aggregation' do
    name = 'type_of_territory'
    aggregation_hash = {
      'type_of_territory' => {
        'doc_count'=> 169,
        'buckets'=> [
          {'key' => 'T', 'doc_count' => 64},
          {'key' => 'F', 'doc_count' => 17}
        ]
      }
    }
    configuration_hash = {
      'type' => 'boolean',
      'query' => 'marine',
      'labels' => {
        'T' => 'Marine',
        'F' => 'Terrestrial'
      },
      'identifiers' => {
        'T' => true,
        'F' => false
      }
    }

    expected_response = [{
      query: 'marine',
      identifier: true,
      label: 'Marine',
      count: 64
    }, {
      query: 'marine',
      identifier: false,
      label: 'Terrestrial',
      count: 17
    }]

    aggregations = Search::Aggregators::Boolean.build(name, aggregation_hash, configuration_hash)
    assert_same_elements expected_response, aggregations
  end
end
