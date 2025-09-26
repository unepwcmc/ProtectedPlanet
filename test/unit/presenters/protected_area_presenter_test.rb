# frozen_string_literal: true

require 'test_helper'

class ProtectedAreaPresenterTest < ActiveSupport::TestCase
  test '#parcels_attribute, test a protected area\'s with multiple parcels' do
    time = Time.local(2025, 0o4, 0o7)
    region = FactoryGirl.create(:region, id: 225_672, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 2_265_721, iso_3: 'MBN', name: 'Manboneland', region: region)
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
