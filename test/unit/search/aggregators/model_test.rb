require 'test_helper'

class SearchAggregatorsModel < ActiveSupport::TestCase
  test '.build, given a name and aggregation hash, returns a model and a count' do
    country_1 = FactoryGirl.create(:country)
    country_2 = FactoryGirl.create(:country)

    name = 'country'
    aggregation_hash = {
      'country' => {
        'doc_count'=> 169,
        'aggregation' => {
          'buckets'=> [
            {'key' => country_1.id, 'doc_count' => 64},
            {'key' => country_2.id, 'doc_count' => 17}
          ]
        }
      }
    }
    configuration_hash = {
      'type' => 'model',
      'class' => 'Country'
    }

    expected_response = [{
      query: 'country',
      identifier: country_1.iso_3,
      label: country_1.name,
      count: 64
    }, {
      query: 'country',
      identifier: country_2.iso_3,
      label: country_2.name,
      count: 17
    }]

    aggregations = Search::Aggregators::Model.build(name, aggregation_hash, configuration_hash)
    assert_same_elements expected_response, aggregations
  end
end
