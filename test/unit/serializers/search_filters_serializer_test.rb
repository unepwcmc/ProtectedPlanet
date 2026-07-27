require 'test_helper'

# Structural snapshot of the search-filters JSON contract sent to the frontend.
# We assert the *shape* -- filter ids, types, option ids, and the international-
# designation filtering -- rather than the exact translated titles, so the test
# catches upgrade-induced contract drift without breaking on copy edits.
class SearchFiltersSerializerTest < ActiveSupport::TestCase
  def build_search(aggregations)
    # Search::BaseSerializer only requires an object that is_a?(Search) and
    # responds to results / search_term / current_page / aggregations.
    stub(is_a?: true, results: nil, search_term: '', current_page: 1,
         aggregations: aggregations)
  end

  setup do
    @aggregations = {
      'designation' => [
        { label: 'World Heritage Site (natural or mixed)', identifier: 2 },
        { label: 'Some National Designation', identifier: 1 }
      ],
      'governance' => [{ label: 'Federal', identifier: 1 }],
      'iucn_category' => [
        { label: 'II', identifier: 2 },
        { label: 'Ia', identifier: 1 }
      ],
      'country' => [{ label: 'Testland', identifier: 1 }],
      'region' => [{ label: 'Europe', identifier: 1 }]
    }
  end

  test 'top-level filter ids and types are stable' do
    result = Search::FiltersSerializer.new(build_search(@aggregations)).serialize
    filters = result.first[:filters]

    ids   = filters.map { |f| f[:id] }
    types = filters.map { |f| f[:type] }

    assert_equal %w[db_type is_type special_status designation location
                    designation governance iucn_category], ids
    assert_equal %w[checkbox checkbox checkbox checkbox checkbox-search
                    checkbox checkbox checkbox], types
  end

  test 'static option ids for db_type / is_type / special_status are stable' do
    filters = Search::FiltersSerializer.new(build_search(@aggregations)).serialize.first[:filters]
    by_id = ->(id) { filters.find { |f| f[:id] == id } }

    assert_equal %w[oecm wdpa], by_id.call('db_type')[:options].map { |o| o[:id] }
    assert_equal %w[terrestrial marine], by_id.call('is_type')[:options].map { |o| o[:id] }
    assert_equal(
      %w[pa_or_any_its_parcels_is_greenlisted
         pa_or_any_its_parcels_is_greenlist_candidate
         has_parcc_info is_transboundary],
      by_id.call('special_status')[:options].map { |o| o[:id] }
    )
  end

  test 'international designation filter only keeps whitelisted designations' do
    filters = Search::FiltersSerializer.new(build_search(@aggregations)).serialize.first[:filters]
    intl = filters.find { |f| f[:id] == 'designation' && f[:name] == 'designation' }

    assert_equal(
      [{ id: 'World Heritage Site (natural or mixed)',
         title: 'World Heritage Site (natural or mixed)' }],
      intl[:options]
    )
  end

  test 'aggregation-backed designation options are sorted by label' do
    filters = Search::FiltersSerializer.new(build_search(@aggregations)).serialize.first[:filters]
    # the second (aggregation-driven) designation filter has no :name key
    desig = filters.select { |f| f[:id] == 'designation' }.last

    assert_equal ['Some National Designation', 'World Heritage Site (natural or mixed)'],
                 desig[:options].map { |o| o[:id] }
  end

  test 'iucn_category options are sorted by identifier, not label' do
    filters = Search::FiltersSerializer.new(build_search(@aggregations)).serialize.first[:filters]
    iucn = filters.find { |f| f[:id] == 'iucn_category' }

    # identifier order (Ia=1 before II=2), which differs from label order
    assert_equal %w[Ia II], iucn[:options].map { |o| o[:id] }
  end
end
