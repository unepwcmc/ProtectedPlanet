require 'test_helper'

class ProtectedAreaPresenterTest < ActiveSupport::TestCase
  test '#data_info returns an hash of sections, with the information
   on the protected area\'s attributes' do
    pa = FactoryGirl.create(
      :protected_area,
      wdpa_parent_id: '123',
      sources: [FactoryGirl.create(:source)],
      name: 'San Guillermo',
      original_name: 'San Guillermo',
      marine: true,
      gis_area: 0.0000231,
      countries: [FactoryGirl.create(:country)],
      iucn_category: FactoryGirl.create(:iucn_category),
      designation: FactoryGirl.create(:designation)
    )

    expected_response = {
      'Basic Info' => [
        {label: 'WDPA ID', complete: true},
        {label: 'WDPA Parent ID', complete: true},
        {label: 'Source', complete: true},
        {label: 'Name', complete: true},
        {label: 'Original Name', complete: true},
        {label: 'Marine/Terrestrial', complete: true}
      ], 'Geometries' => [
        {label: 'GIS Marine Area', complete: false},
        {label: 'GIS Area', complete: true},
        {label: 'Geometry', complete: false}
      ], 'Categorisation' => [
        {label: 'Country', complete: true},
        {label: 'Sublocations', complete: true},
        {label: 'IUCN Category', complete: true},
        {label: 'Governance', complete: true},
        {label: 'Management Authority', complete: false},
        {label: 'Management Plan', complete: false},
        {label: 'International Criteria', complete: false},
        {label: 'Designation', complete: true},
        {label: 'Jurisdiction', complete: false}
      ], 'Special' => [
        {label: 'No-take Status', complete: false},
        {label: 'No-take Area', complete: false}
      ]
    }

    presenter = ProtectedAreaPresenter.new(pa)

    assert_equal expected_response, presenter.data_info
  end

  test '#percentage_complete returns the percentage
   of the WDPA attributes that are filled' do
    pa = FactoryGirl.create(:protected_area,
      wdpa_id: 1234,
      name: 'An Protected Area',
      original_name: 'Not an protected area'
    )

    presenter = ProtectedAreaPresenter.new(pa)

    assert_equal 45.0, presenter.percentage_complete
  end

  test '#percentage_complete handles false attributes as present, not nil' do
    pa1 = FactoryGirl.create(:protected_area,
      wdpa_id: 1234,
      name: 'An Protected Area',
      original_name: 'Not an protected area',
      marine: false
    )
    pa2 = FactoryGirl.create(:protected_area,
      wdpa_id: 5678,
      name: 'Another Protected Area',
      original_name: 'Not another protected area',
      marine: true
    )

    presenter1 = ProtectedAreaPresenter.new(pa1)
    presenter2 = ProtectedAreaPresenter.new(pa2)

    assert_equal 50.0, presenter1.percentage_complete
    assert_equal 50.0, presenter2.percentage_complete
  end

  test '#percentage_complete handles polygons and points' do
    point = "MULTIPOINT ((0 0))"
    polygon = "MULTIPOLYGON (((0 0, 1 1, 3 3, 0 0)))"
    pa1 = FactoryGirl.create(:protected_area,
      wdpa_id: 1234,
      name: 'An Protected Area',
      original_name: 'Not an protected area',
      marine: false,
      the_geom: RGeo::Geos.factory.parse_wkt(point)
    )
    pa2 = FactoryGirl.create(:protected_area,
      wdpa_id: 5678,
      name: 'Another Protected Area',
      original_name: 'Not another protected area',
      marine: true,
      the_geom: RGeo::Geos.factory.parse_wkt(polygon)
    )

    presenter1 = ProtectedAreaPresenter.new(pa1)
    presenter2 = ProtectedAreaPresenter.new(pa2)

    assert_equal 50.0, presenter1.percentage_complete
    assert_equal 55.0, presenter2.percentage_complete
  end
end
