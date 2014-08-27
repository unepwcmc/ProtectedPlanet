require 'test_helper'

class SearchFilterTest < ActiveSupport::TestCase
  test '.to_h, given a nested Filter, returns the filter query as a
   hash' do
    term = 3
    options = {
      type: 'nested',
      path: 'countries.region',
      field: 'countries.region.id',
      required: true
    }

    filter = Search::Filter.new(term, options)

    expected_hash = {
      "nested" => {
        "path" => "countries.region",
        "filter" => {
           "bool" => {
              "must" => {
                "term" => {
                  "countries.region.id" => 3
                }
              }
            }
        }
      }
    }

    assert_equal filter.to_h, expected_hash
  end

  test '.to_h, given a type Filter, returns the filter query as a
   hash' do
    term = 'country'
    options = {
      type: 'type'
    }

    filter = Search::Filter.new(term, options)

    expected_hash = {
      "type" => {
        "value" => term
      }
    }

    assert_equal filter.to_h, expected_hash
  end
end
