require 'test_helper'

class SearchAggregatorsGroupedTest < ActiveSupport::TestCase
  test '.build, given a name, raw aggregations, and a configuration hash,
   returns the computed aggregation' do
    name = 'related_sources'
    aggregation_hash = {
      'has_parcc_info' => {
        'doc_count'=> 220,
        'buckets'=> [
          {'key' => 'T', 'doc_count' => 200},
          {'key' => 'F', 'doc_count' => 20}
        ]
      },
      'has_irreplaceability_info' => {
        'doc_count'=> 12,
        'buckets'=> [
          {'key' => 'T', 'doc_count' => 10},
          {'key' => 'F', 'doc_count' => 2}
        ]
      }
    }
    configuration_hash = {
      'type' => 'grouped',
      'members' => {
        'has_parcc_info' => {
          'type' => 'boolean',
          'query' => 'has_parcc_info',
          'identifiers' => { 'T' => true },
          'labels' => { 'T' => 'Vulnerability Assessment' }
        },
        'has_irreplaceability_info' => {
          'type' => 'boolean',
          'query' => 'has_irreplaceability_info',
          'identifiers' => { 'T' => true },
          'labels' => { 'T' => 'Irreplaceability Assessment' }
        }
      }
    }

    expected_response = [{
      query: 'has_parcc_info',
      identifier: true,
      label: 'Vulnerability Assessment',
      count: 200
    }, {
      query: 'has_irreplaceability_info',
      identifier: true,
      label: 'Irreplaceability Assessment',
      count: 10
    }]

    aggregations = Search::Aggregators::Grouped.build(name, aggregation_hash, configuration_hash)
    assert_same_elements expected_response, aggregations
  end
end

