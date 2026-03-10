require 'test_helper'
require 'rgeo'

class ProtectedAreaTest < ActiveSupport::TestCase
  test '.create creates a postgis geometry from a WKT geometry' do
    protected_area = ProtectedArea.create(the_geom: 'POINT (1.0 1.0)')

    assert_kind_of RGeo::Geos::CAPIPointImpl, protected_area.the_geom
    assert_equal   'POINT (1.0 1.0)', protected_area.the_geom.to_s
  end

  test ".save creates a slug attribute consisting of parameterized name
   and designation" do
    designation = FactoryGirl.create(:designation, name: 'Protected Area')
    protected_area = ProtectedArea.create(name: 'Finn and Jake Land', designation: designation)

    assert_equal 'finn-and-jake-land-protected-area', protected_area.slug
  end

  test ".save creates a slug attribute consisting of parameterized name
   only, if designation is not set" do
    protected_area = ProtectedArea.create(name: 'Finn and Jake Land')

    assert_equal 'finn-and-jake-land', protected_area.slug
  end

  test '.bounds returns the bounding box for the PA geometry' do
    protected_area = FactoryGirl.create(:protected_area, the_geom: 'POLYGON ((-1.5 0, 0 1, 1 2, 1 0, -1.5 0))')

    assert_equal [[0, -1.5], [2, 1]], protected_area.bounds
  end

  test '.bounds only calls the database once' do
    protected_area = FactoryGirl.create(:protected_area, the_geom: 'POLYGON ((-1.5 0, 0 1, 1 2, 1 0, -1.5 0))')

    ActiveRecord::Base.connection.expects(:execute).returns([{}]).once

    protected_area.bounds
  end

  test '.without_geometry does not select the_geom' do
    geometry_wkt = 'POLYGON ((30 10, 40 40, 20 40, 10 20, 30 10))'
    protected_area = FactoryGirl.create(:protected_area, the_geom: geometry_wkt)

    selected_protected_area = ProtectedArea.without_geometry.find(protected_area.id)
    refute selected_protected_area.has_attribute?(:the_geom)
  end

  test '.as_indexed_json returns the PA as JSON with nested attributes' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, name: 'Manboneland', region: region)

    iucn_category = FactoryGirl.create(:iucn_category, id: 456, name: 'IA')
    designation = FactoryGirl.create(:designation, id: 654, name: 'National')
    governance = FactoryGirl.create(:governance, id: 654, name: 'Regional')

    pa = FactoryGirl.create(:protected_area,
      name: 'Manbone', countries: [country],
      original_name: 'Manboné', iucn_category: iucn_category,
      designation: designation, marine: true, site_id: 555_999,
      governance: governance,
      the_geom_latitude: 1, the_geom_longitude: 2,
      has_irreplaceability_info: true, has_parcc_info: false)

    expected_json = {
      'id' => pa.id,
      'site_id' => 555_999,
      'name' => 'Manbone',
      'original_name' => 'Manboné',
      'marine' => true,
      'has_irreplaceability_info' => true,
      'has_parcc_info' => false,
      'pa_or_any_its_parcels_is_greenlisted' => false,
      'is_oecm' => false,
      'coordinates' => [2.0, 1.0],
      'countries_for_index' => [
        {
          'id' => 123,
          'name' => 'Manboneland',
          'iso_3' => 'MTX',
          'region_for_index' => {
            'id' => 987,
            'name' => 'North Manmerica'
          }
        }
      ],
      'iucn_category' => {
        'id' => 456,
        'name' => 'IA'
      },
      'designation' => {
        'id' => 654,
        'name' => 'National'
      },
      'governance' => {
        'id' => 654,
        'name' => 'Regional'
      }
    }

    assert_equal expected_json, pa.as_indexed_json
  end

  test '#with_valid_iucn_categories returns PAs with valid IUCN
   categories' do
    iucn_category_1 = FactoryGirl.create(:iucn_category, name: 'Ib')
    iucn_category_2 = FactoryGirl.create(:iucn_category, name: 'V')
    no_iucn_category = FactoryGirl.create(:iucn_category, name: 'Cristiano Ronaldo')

    FactoryGirl.create(:protected_area, iucn_category: iucn_category_1)
    FactoryGirl.create(:protected_area, iucn_category: iucn_category_2)
    FactoryGirl.create(:protected_area, iucn_category: no_iucn_category)
    assert_equal 2, ProtectedArea.with_valid_iucn_categories.count
  end

  test '.nearest_protected_areas returns the closest 2 PAs, ordered by
   distance ASC and memoizes the result' do
    pa = FactoryGirl.create(:protected_area, the_geom_latitude: 1, the_geom_longitude: 0)

    search_mock = mock.tap { |m| m.expects(:results).returns([FactoryGirl.create(:protected_area)]) }
    Search.expects(:search)
      .with('', { size: 3, filters: { location: { coords: [0, 1] } }, sort: { geo_distance: [0, 1] } })
      .returns(search_mock)
      .once

    pa.nearest_protected_areas
    nearest = pa.nearest_protected_areas
    assert_equal 1, nearest.length
  end

  test '::most_visited, given a date, returns an array of most visited PAs for the month' do
    pa1 = FactoryGirl.create(:protected_area, site_id: 345)
    pa2 = FactoryGirl.create(:protected_area, site_id: 123)

    $redis.expects(:zrevrangebyscore).with(
      '09-1955', '+inf', '-inf', { with_scores: true, limit: [0, 3] }
    ).returns([['345', 4.0], ['123', 1.0]])

    assert_equal(
      [{ protected_area: pa1, visits: 4 }, { protected_area: pa2, visits: 1 }],
      ProtectedArea.most_visited(DateTime.new(1955, 9, 12))
    )
  end

  # Green list scopes and instance methods
  test '.pas_with_green_list_on_self_only returns only PAs with green_list_status on the PA record' do
    gl = FactoryGirl.create(:green_list_status, gl_status: 'Green Listed')
    pa_with_gl = FactoryGirl.create(:protected_area, site_id: 901, green_list_status: gl)
    FactoryGirl.create(:protected_area, site_id: 902)

    result = ProtectedArea.pas_with_green_list_on_self_only
    assert_includes result, pa_with_gl
    assert_equal 1, result.count
  end

  test '.pas_with_green_list_on_self_or_any_parcel returns PAs with green list on self or any parcel' do
    gl_pa = FactoryGirl.create(:green_list_status, gl_status: 'Green Listed')
    gl_parcel = FactoryGirl.create(:green_list_status, gl_status: 'Relisted')
    pa_self = FactoryGirl.create(:protected_area, site_id: 801, green_list_status: gl_pa)
    pa_parcel_only = FactoryGirl.create(:protected_area, site_id: 802)
    FactoryGirl.create(:protected_area_parcel, site_id: pa_parcel_only.site_id, site_pid: '802_A', green_list_status: gl_parcel)
    pa_none = FactoryGirl.create(:protected_area, site_id: 803)

    result = ProtectedArea.pas_with_green_list_on_self_or_any_parcel
    assert_includes result.to_a, pa_self
    assert_includes result.to_a, pa_parcel_only
    refute_includes result.to_a, pa_none
    assert result.count >= 2
  end

  test '#pa_or_any_its_parcels_is_greenlisted is true when PA has Green Listed or Relisted' do
    gl = FactoryGirl.create(:green_list_status, gl_status: 'Green Listed')
    pa = FactoryGirl.create(:protected_area, site_id: 701, green_list_status: gl)
    assert pa.pa_or_any_its_parcels_is_greenlisted

    relisted = FactoryGirl.create(:green_list_status, gl_status: 'Relisted')
    pa2 = FactoryGirl.create(:protected_area, site_id: 702, green_list_status: relisted)
    assert pa2.pa_or_any_its_parcels_is_greenlisted
  end

  test '#pa_or_any_its_parcels_is_greenlisted is true when only a parcel is green listed' do
    gl = FactoryGirl.create(:green_list_status, gl_status: 'Green Listed')
    pa = FactoryGirl.create(:protected_area, site_id: 703)
    FactoryGirl.create(:protected_area_parcel, site_id: pa.site_id, site_pid: '703_A', green_list_status: gl)
    assert pa.pa_or_any_its_parcels_is_greenlisted
  end

  test '#pa_or_any_its_parcels_is_greenlisted is false when PA and parcels have no green list' do
    pa = FactoryGirl.create(:protected_area, site_id: 704)
    assert_not pa.pa_or_any_its_parcels_is_greenlisted
  end

  test '#pa_or_any_its_parcels_is_greenlist_candidate is true when PA is Candidate' do
    gl = FactoryGirl.create(:green_list_status, :candidate)
    pa = FactoryGirl.create(:protected_area, site_id: 705, green_list_status: gl)
    assert pa.pa_or_any_its_parcels_is_greenlist_candidate
  end

  test '#pa_or_any_its_parcels_is_greenlist_candidate is true when only a parcel is Candidate' do
    gl = FactoryGirl.create(:green_list_status, :candidate)
    pa = FactoryGirl.create(:protected_area, site_id: 706)
    FactoryGirl.create(:protected_area_parcel, site_id: pa.site_id, site_pid: '706_A', green_list_status: gl)
    assert pa.pa_or_any_its_parcels_is_greenlist_candidate
  end

  test '#pa_or_any_its_parcels_is_greenlist_candidate is false when PA is Green Listed' do
    gl = FactoryGirl.create(:green_list_status, gl_status: 'Green Listed')
    pa = FactoryGirl.create(:protected_area, site_id: 707, green_list_status: gl)
    assert_not pa.pa_or_any_its_parcels_is_greenlist_candidate
  end
end
