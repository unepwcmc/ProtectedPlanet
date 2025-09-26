# frozen_string_literal: true

require 'test_helper'

class ProtectedAreaPresenterTest < ActiveSupport::TestCase
  test '#data_info returns an hash of sections, with the information
   on the protected area\'s attributes' do
    pa = FactoryGirl.create(
      :protected_area,
      site_pid: '123',
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
        { label: 'WDPA ID', complete: true },
        { label: 'WDPA Parent ID', complete: true },
        { label: 'Source', complete: true },
        { label: 'Name', complete: true },
        { label: 'Original Name', complete: true },
        { label: 'Marine/Terrestrial', complete: true }
      ], 'Geometries' => [
        { label: 'GIS Marine Area', complete: false },
        { label: 'GIS Area', complete: true },
        { label: 'Geometry', complete: false }
      ], 'Categorisation' => [
        { label: 'Country', complete: true },
        { label: 'Sublocations', complete: true },
        { label: 'IUCN Category', complete: true },
        { label: 'Governance', complete: true },
        { label: 'Management Authority', complete: false },
        { label: 'Management Plan', complete: false },
        { label: 'International Criteria', complete: false },
        { label: 'Designation', complete: true },
        { label: 'Jurisdiction', complete: true }
      ], 'Special' => [
        { label: 'No-take Status', complete: false },
        { label: 'No-take Area', complete: false }
      ]
    }

    presenter = ProtectedAreaPresenter.new(pa)

    assert_equal expected_response, presenter.data_info
  end

  test '#percentage_complete returns the percentage
   of the WDPA attributes that are filled' do
    pa = FactoryGirl.create(:protected_area,
      site_id: 1234,
      name: 'An Protected Area',
      original_name: 'Not an protected area')

    presenter = ProtectedAreaPresenter.new(pa)

    assert_equal 50.0, presenter.percentage_complete
  end

  test '#percentage_complete handles false attributes as present, not nil' do
    pa1 = FactoryGirl.create(:protected_area,
      site_id: 1234,
      name: 'An Protected Area',
      original_name: 'Not an protected area',
      marine: false)
    pa2 = FactoryGirl.create(:protected_area,
      site_id: 5678,
      name: 'Another Protected Area',
      original_name: 'Not another protected area',
      marine: true)

    presenter1 = ProtectedAreaPresenter.new(pa1)
    presenter2 = ProtectedAreaPresenter.new(pa2)

    assert_equal 55.0, presenter1.percentage_complete
    assert_equal 55.0, presenter2.percentage_complete
  end

  test '#percentage_complete handles polygons and points' do
    point = 'MULTIPOINT ((0 0))'
    polygon = 'MULTIPOLYGON (((0 0, 1 1, 3 3, 0 0)))'
    pa1 = FactoryGirl.create(:protected_area,
      site_id: 1234,
      name: 'An Protected Area',
      original_name: 'Not an protected area',
      marine: false,
      the_geom: RGeo::Geos.factory.parse_wkt(point))
    pa2 = FactoryGirl.create(:protected_area,
      site_id: 5678,
      name: 'Another Protected Area',
      original_name: 'Not another protected area',
      marine: true,
      the_geom: RGeo::Geos.factory.parse_wkt(polygon))

    presenter1 = ProtectedAreaPresenter.new(pa1)
    presenter2 = ProtectedAreaPresenter.new(pa2)

    assert_equal 55.0, presenter1.percentage_complete
    assert_equal 60.0, presenter2.percentage_complete
  end
  test '#parcels_attribute, test a protected area\'s with multiple parcels' do
    time = Time.local(2025, 0o4, 0o7)
    region = FactoryGirl.create(:region, id: 225_672, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 2_265_721, iso_3: 'MBN', name: 'Manboneland', region: region)
    sub_location = FactoryGirl.create(:sub_location, iso: 'ABC')
    iucn_category = FactoryGirl.create(:iucn_category, id: 775_677, name: 'IA')
    jurisdiction = FactoryGirl.create(:jurisdiction, id: 765_677, name: 'International')
    designation = FactoryGirl.create(:designation, id: 876_567, name: 'National', jurisdiction: jurisdiction)
    governance = FactoryGirl.create(:governance, id: 96_767, name: 'Bone Man')
    legal_status = FactoryGirl.create(:legal_status, id: 56_767, name: 'Proposed')
    management_authority = FactoryGirl.create(:management_authority, name: 'Authority of Authorities')
    pa_parcel_base = {
      site_id: 555_999,
      site_pid: '555999_A',
      name: 'San GuillermoAAA',
      original_name: 'San GuillermoAAA',
      marine: true,
      gis_area: 0.0000231,
      countries: [country],
      sub_locations: [sub_location],
      iucn_category: iucn_category,
      designation: designation,
      governance: governance,
      management_plan: 'A plan',
      management_authority: management_authority,
      international_criteria: '(ii)(iv)',
      legal_status: legal_status,
      legal_status_updated_at: time,
      reported_area: 10.2
    }
    pa_info_base = pa_parcel_base.merge(sources: [FactoryGirl.create(:source)])
    parcel_a_info = pa_parcel_base
    # Create PA
    pa = FactoryGirl.create(:protected_area, pa_info_base)

    # Create All parcels (3 in this test)
    FactoryGirl.create(:protected_area_parcel, parcel_a_info)

    parcel_b_info = pa_parcel_base
    parcel_b_info[:site_pid] = '555999_B'
    parcel_b_info[:name] = 'San GuillermoBBBBB'
    parcel_b_info[:original_name] = 'San GuillermoBBBBB'
    FactoryGirl.create(:protected_area_parcel, parcel_b_info)

    parcel_c_info = pa_parcel_base
    parcel_c_info[:site_pid] = '555999_C'
    parcel_c_info[:name] = 'San GuillermoCCC'
    parcel_c_info[:original_name] = 'San GuillermoCCC'
    FactoryGirl.create(:protected_area_parcel, parcel_c_info)

    # Sublocation
    expected_response = [
      {
        site_pid: '555999_A',
        attributes: [
          { title: 'Original Name', value: 'San GuillermoAAA' },
          { title: 'English Designation', value: 'National' },
          { title: 'IUCN Management Category', value: 'IA' },
          { title: 'Status', value: 'Proposed' },
          { title: 'Type of Designation', value: 'International' },
          { title: 'Status Year', value: time.year.to_s },
          { title: 'Sublocation', value: 'ABC' },
          { title: 'Governance Type', value: 'Bone Man' },
          { title: 'Management Authority', value: 'Authority of Authorities' },
          { title: 'Management Plan', value: 'A plan' },
          { title: 'International Criteria', value: '(ii)(iv)' }
        ]
      },
      {
        site_pid: '555999_B',
        attributes: [
          { title: 'Original Name', value: 'San GuillermoBBBBB' },
          { title: 'English Designation', value: 'National' },
          { title: 'IUCN Management Category', value: 'IA' },
          { title: 'Status', value: 'Proposed' },
          { title: 'Type of Designation', value: 'International' },
          { title: 'Status Year', value: time.year.to_s },
          { title: 'Sublocation', value: 'ABC' },
          { title: 'Governance Type', value: 'Bone Man' },
          { title: 'Management Authority', value: 'Authority of Authorities' },
          { title: 'Management Plan', value: 'A plan' },
          { title: 'International Criteria', value: '(ii)(iv)' }
        ]
      },
      {
        site_pid: '555999_C',
        attributes: [
          { title: 'Original Name', value: 'San GuillermoCCC' },
          { title: 'English Designation', value: 'National' },
          { title: 'IUCN Management Category', value: 'IA' },
          { title: 'Status', value: 'Proposed' },
          { title: 'Type of Designation', value: 'International' },
          { title: 'Status Year', value: time.year.to_s },
          { title: 'Sublocation', value: 'ABC' },
          { title: 'Governance Type', value: 'Bone Man' },
          { title: 'Management Authority', value: 'Authority of Authorities' },
          { title: 'Management Plan', value: 'A plan' },
          { title: 'International Criteria', value: '(ii)(iv)' }
        ]
      }
    ]

    presenter = ProtectedAreaPresenter.new(pa)
    assert_equal expected_response, presenter.parcels_attribute
  end
  test '#parcels_attribute, test a protected area\'s with only one parcel' do
    time = Time.local(2025, 0o4, 0o7)
    region = FactoryGirl.create(:region, id: 225_672, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 2_265_721, iso_3: 'MBN', name: 'Manboneland', region: region)
    sub_location = FactoryGirl.create(:sub_location, iso: 'ABC')
    iucn_category = FactoryGirl.create(:iucn_category, id: 775_677, name: 'IA')
    jurisdiction = FactoryGirl.create(:jurisdiction, id: 765_677, name: 'International')
    designation = FactoryGirl.create(:designation, id: 876_567, name: 'National', jurisdiction: jurisdiction)
    governance = FactoryGirl.create(:governance, id: 96_767, name: 'Bone Man')
    legal_status = FactoryGirl.create(:legal_status, id: 56_767, name: 'Proposed')
    management_authority = FactoryGirl.create(:management_authority, name: 'Authority of Authorities')
    pa_info_base = {
      site_id: 555_999,
      site_pid: '555999',
      name: 'San GuillermoAAA',
      original_name: 'San GuillermoAAA',
      marine: true,
      gis_area: 0.0000231,
      countries: [country],
      sub_locations: [sub_location],
      iucn_category: iucn_category,
      designation: designation,
      governance: governance,
      management_plan: 'A plan',
      management_authority: management_authority,
      international_criteria: '(ii)(iv)',
      legal_status: legal_status,
      legal_status_updated_at: time,
      reported_area: 10.2,
      sources: [FactoryGirl.create(:source)]
    }
    # Create PA
    pa = FactoryGirl.create(:protected_area, pa_info_base)
    expected_response = [{
      site_pid: '555999',
      attributes: [
        { title: 'Original Name', value: 'San GuillermoAAA' },
        { title: 'English Designation', value: 'National' },
        { title: 'IUCN Management Category', value: 'IA' },
        { title: 'Status', value: 'Proposed' },
        { title: 'Type of Designation', value: 'International' },
        { title: 'Status Year', value: time.year.to_s },
        { title: 'Sublocation', value: 'ABC' },
        { title: 'Governance Type', value: 'Bone Man' },
        { title: 'Management Authority', value: 'Authority of Authorities' },
        { title: 'Management Plan', value: 'A plan' },
        { title: 'International Criteria', value: '(ii)(iv)' }
      ]
    }]

    presenter = ProtectedAreaPresenter.new(pa)
    assert_equal expected_response, presenter.parcels_attribute
  end
end
