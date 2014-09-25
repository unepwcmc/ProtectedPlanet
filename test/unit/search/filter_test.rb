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

  test '#from_params, given a hash of search params, returns the filter query
   as a hash' do
    filters = Search::Filter.from_params(type: 'protected_area')

    expected_filters = [{
      "type" => {
        "value" => 'protected_area'
      }
    }]

    assert_equal filters, expected_filters
  end

  test '#new, given an integer filter passed as a string, converts
   the string to an integer' do
    term = "3"
    options = {
      type: 'nested',
      path: 'countries_for_index.region_for_index',
      field: 'countries_for_index.region_for_index.id',
      required: true
    }

    filter = Search::Filter.new(term, options)

    expected_hash = {
      "nested" => {
        "path" => "countries_for_index.region_for_index",
        "filter" => {
           "bool" => {
              "must" => {
                "term" => {
                  "countries_for_index.region_for_index.id" => 3
                }
              }
            }
        }
      }
    }

    assert_equal filter.to_h, expected_hash
  end
end
