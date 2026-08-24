require 'test_helper'

# /en/search-areas and /en/search-areas-results were 6.5s and 8.3s on staging because
# every search attaches nine aggregations (six of them `nested`) and, with no search
# term, they run across the whole index. Search caches the Elasticsearch response for
# blank-term searches so that cost is paid once per TTL rather than per request.
class SearchResponseCacheTest < ActiveSupport::TestCase
  RESPONSE = { 'hits' => { 'total' => 0, 'hits' => [] }, 'aggregations' => {} }.freeze

  setup do
    Rails.cache.clear
    @calls = 0
  end

  # Counts how many times the query actually reaches Elasticsearch.
  def counting_client
    client = Object.new
    calls = -> { @calls += 1 }
    client.define_singleton_method(:search) do |*|
      calls.call
      RESPONSE
    end
    client
  end

  def run_search(term, options = {})
    search = Search.new(term, options, Search::PA_INDEX)
    search.instance_variable_set(:@elastic_search, counting_client)
    search.search
    search
  end

  test 'a blank-term search hits elasticsearch once and is served from cache after' do
    3.times { run_search(nil) }

    assert_equal 1, @calls, 'blank-term searches should reach Elasticsearch only once'
  end

  test 'a typed search term is never cached' do
    # Bounded cardinality is the whole reason blank terms are safe to cache; typed
    # terms are unbounded, and they are already fast because the term narrows the
    # documents the aggregations run over.
    3.times { run_search('serengeti') }

    assert_equal 3, @calls, 'typed search terms must not be cached'
  end

  test 'different filters are cached separately' do
    run_search(nil, filters: { governance: ['federal'] })
    run_search(nil, filters: { governance: ['local'] })
    run_search(nil, filters: { governance: ['federal'] })

    assert_equal 2, @calls, 'each distinct filter set needs its own cache entry'
  end

  test 'paging is part of the cache key' do
    run_search(nil, page: 1)
    run_search(nil, page: 2)
    run_search(nil, page: 1)

    assert_equal 2, @calls, 'page must not be collapsed into one cache entry'
  end
end
