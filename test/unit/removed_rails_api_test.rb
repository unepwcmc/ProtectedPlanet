require 'test_helper'

# Runtime-only regressions from the Rails 5.2 -> 8.0 / Ruby 2.6 -> 3.3 upgrade.
#
# Each of these was invisible to the test suite and to a static deprecation sweep,
# and only failed on a real server against real data. They are grouped here because
# they share a shape: an API that still parses fine, on a code path no test reached.
class RemovedRailsApiTest < ActiveSupport::TestCase
  # ActiveStorage::Blob#service_url was deprecated in Rails 6.1 and REMOVED in 7.0
  # (renamed to #url). All three call sites sat on the non-development branch, so
  # they raised NoMethodError on staging and production only -- GET /search-cms
  # with a search term 500'd the moment any result carried an image.
  test 'no ActiveStorage service_url calls remain' do
    offenders = Dir.glob(Rails.root.join('{app,lib}/**/*.rb')).select do |file|
      File.read(file).match?(/(?<!#\s)\.service_url\b/)
    end

    assert_empty offenders.map { |f| f.sub("#{Rails.root}/", '') },
                 'ActiveStorage::Blob#service_url was removed in Rails 7.0 -- use #url'
  end

  # URI::DEFAULT_PARSER.escape treats [ and ] as safe: RFC 2396 reserves them for
  # IPv6 literals in the HOST component. Every GeoJSON geometry is full of them
  # ("coordinates":[[[-61.8,17.1],...]]), so they survived into the URL path and
  # URI() rejected the whole thing, 500ing /assets/tiles/:id for every area type.
  test 'AssetGenerator escapes square brackets so the tile URL parses' do
    geojson = '{"type":"Feature","geometry":{"type":"Polygon",' \
              '"coordinates":[[[-61.825,17.185],[-61.887,17.205]]]}}'

    escaped = AssetGenerator.escape_for_path(geojson)

    refute_includes escaped, '[', 'unescaped [ makes URI() raise InvalidURIError'
    refute_includes escaped, ']'
    assert_includes escaped, '%5B'
    assert_includes escaped, '%5D'

    url = "https://api.mapbox.com/styles/v1/x/y/static/geojson(#{escaped})/auto/304x138@2x"
    assert_nothing_raised { URI(url) }
  end

  test 'AssetGenerator still leaves genuinely safe characters alone' do
    # Over-escaping would break the path structure Mapbox expects.
    escaped = AssetGenerator.escape_for_path('a,b:c/d')

    assert_equal 'a,b:c/d', escaped
  end

  # Searchable#filters returns '' rather than {} when no filters are supplied, so
  # options is {filters: ''}. Hash#dig then called ''.dig(:ancestor) and raised
  # "String does not have #dig method" -- an unfiltered /search-cms 500'd on
  # production as well as staging. It only ever worked because the frontend always
  # sends filters.
  # Search::BaseSerializer type-checks its argument, so this uses a real Search
  # with only #options stubbed -- that is the value under test.
  def search_with_options(options)
    Search.new('anything', options, Search::CMS_INDEX)
  end

  test 'CmsSerializer tolerates the empty-String filters value' do
    serializer = Search::CmsSerializer.new(search_with_options({ filters: '', page: 1, size: 9 }), {})

    assert_nothing_raised do
      assert_equal :default, serializer.send(:cms_root_page_slug)
    end
  end

  test 'CmsSerializer still reads the ancestor filter when one is present' do
    serializer = Search::CmsSerializer.new(search_with_options({ filters: { ancestor: -1 } }), {})

    # A Hash filters value must still be traversed; an unknown id falls back.
    assert_equal :default, serializer.send(:cms_root_page_slug)
  end
end
