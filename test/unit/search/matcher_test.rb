require 'test_helper'

class SearchMatcherTest < ActiveSupport::TestCase
  test '.to_h, given a nested Matcher, returns the matcher query as a
   hash' do
    term = 'hashie'
    options = {
      type: 'nested',
      path: 'countries',
      fields: ['countries.name']
    }

    matcher = Search::Matcher.new(term, options)

    expected_hash = {
      "nested" => {
        "path" => "countries",
        "query" => {
          "fuzzy_like_this" => {
            "like_text" => term,
            "fields" => [ "countries.name" ]
          }
        }
      }
    }

    assert_equal matcher.to_h, expected_hash
  end

  test '.to_h, given a multi_match Matcher, returns the matcher query as a
   hash' do
    term = 'hashie'
    options = {
      type: 'multi_match',
      fields: ['name', 'original_name' ]
    }

    matcher = Search::Matcher.new(term, options)

    expected_hash = {
      "multi_match" => {
        "query" => "*#{term}*",
        "fields" => [ "name", "original_name" ]
      }
    }

    assert_equal matcher.to_h, expected_hash
  end
end
