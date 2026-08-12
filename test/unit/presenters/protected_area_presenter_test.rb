# frozen_string_literal: true

require 'test_helper'

class ProtectedAreaPresenterTest < ActiveSupport::TestCase
  test '#current_pa_and_parcels_attributes, test a protected area\'s with multiple parcels' do
    time = Time.local(2025, 0o4, 0o7)
    region = FactoryBot.create(:region, id: 225_672, name: 'North Manmerica')
    country = FactoryBot.create(:country, id: 2_265_721, iso_3: 'MBN', name: 'Manboneland', region: region)
    iucn_category = FactoryBot.create(:iucn_category, id: 775_677, name: 'IA')
    jurisdiction = FactoryBot.create(:jurisdiction, id: 765_677, name: 'International')
    designation = FactoryBot.create(:designation, id: 876_567, name: 'National', jurisdiction: jurisdiction)
    governance = FactoryBot.create(:governance, id: 96_767, name: 'Bone Man')
    legal_status = FactoryBot.create(:legal_status, id: 56_767, name: 'Proposed')
    management_authority = FactoryBot.create(:management_authority, name: 'Authority of Authorities')
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
    pa_info_base = pa_parcel_base.merge(sources: [FactoryBot.create(:source)])
    parcel_a_info = pa_parcel_base
    # Create PA
    pa = FactoryBot.create(:protected_area, pa_info_base)

    # Create All parcels (3 in this test)
    FactoryBot.create(:protected_area_parcel, parcel_a_info)

    parcel_b_info = pa_parcel_base
    parcel_b_info[:site_pid] = '555999_B'
    parcel_b_info[:name] = 'San GuillermoBBBBB'
    parcel_b_info[:original_name] = 'San GuillermoBBBBB'
    FactoryBot.create(:protected_area_parcel, parcel_b_info)

    parcel_c_info = pa_parcel_base
    parcel_c_info[:site_pid] = '555999_C'
    parcel_c_info[:name] = 'San GuillermoCCC'
    parcel_c_info[:original_name] = 'San GuillermoCCC'
    FactoryBot.create(:protected_area_parcel, parcel_c_info)

    expected_response = [{:site_pid=>"555999_A", :attributes=>[{:title=>"Parcel ID", :value=>"555999_A", :is_site_pid=>true}, {:title=>"Name", :value=>"San GuillermoAAA"}, {:title=>"English Name", :value=>"San GuillermoAAA"}, {:title=>"English Designation", :value=>"National"}, {:title=>"IUCN Management Category", :value=>"IA"}, {:title=>"Status", :value=>"Proposed"}, {:title=>"Type of Designation", :value=>"International"}, {:title=>"Status Year", :value=>"2025"}, {:title=>"Governance Type", :value=>"Bone Man"}, {:title=>"Governance Subtype", :value=>"Not Reported"}, {:title=>"Management Authority", :value=>"Authority of Authorities"}, {:title=>"Management Plan", :value=>"A plan"}, {:title=>"Ownership Type", :value=>"Not Reported"}, {:title=>"Ownership Subtype", :value=>"Not Reported"}, {:title=>"International Criteria", :value=>"(ii)(iv)"}, {:title=>"Inland Waters", :value=>"Not Reported"}, {:title=>"Supplementary Information", :value=>nil}]}, {:site_pid=>"555999_B", :attributes=>[{:title=>"Parcel ID", :value=>"555999_B", :is_site_pid=>true}, {:title=>"Name", :value=>"San GuillermoBBBBB"}, {:title=>"English Name", :value=>"San GuillermoBBBBB"}, {:title=>"English Designation", :value=>"National"}, {:title=>"IUCN Management Category", :value=>"IA"}, {:title=>"Status", :value=>"Proposed"}, {:title=>"Type of Designation", :value=>"International"}, {:title=>"Status Year", :value=>"2025"}, {:title=>"Governance Type", :value=>"Bone Man"}, {:title=>"Governance Subtype", :value=>"Not Reported"}, {:title=>"Management Authority", :value=>"Authority of Authorities"}, {:title=>"Management Plan", :value=>"A plan"}, {:title=>"Ownership Type", :value=>"Not Reported"}, {:title=>"Ownership Subtype", :value=>"Not Reported"}, {:title=>"International Criteria", :value=>"(ii)(iv)"}, {:title=>"Inland Waters", :value=>"Not Reported"}, {:title=>"Supplementary Information", :value=>nil}]}, {:site_pid=>"555999_C", :attributes=>[{:title=>"Parcel ID", :value=>"555999_C", :is_site_pid=>true}, {:title=>"Name", :value=>"San GuillermoCCC"}, {:title=>"English Name", :value=>"San GuillermoCCC"}, {:title=>"English Designation", :value=>"National"}, {:title=>"IUCN Management Category", :value=>"IA"}, {:title=>"Status", :value=>"Proposed"}, {:title=>"Type of Designation", :value=>"International"}, {:title=>"Status Year", :value=>"2025"}, {:title=>"Governance Type", :value=>"Bone Man"}, {:title=>"Governance Subtype", :value=>"Not Reported"}, {:title=>"Management Authority", :value=>"Authority of Authorities"}, {:title=>"Management Plan", :value=>"A plan"}, {:title=>"Ownership Type", :value=>"Not Reported"}, {:title=>"Ownership Subtype", :value=>"Not Reported"}, {:title=>"International Criteria", :value=>"(ii)(iv)"}, {:title=>"Inland Waters", :value=>"Not Reported"}, {:title=>"Supplementary Information", :value=>nil}]}]

    presenter = ProtectedAreaPresenter.new(pa)
    assert_equal expected_response, presenter.current_pa_and_parcels_attributes
  end
  test '#current_pa_and_parcels_attributes, test a protected area\'s with only one parcel' do
    time = Time.local(2025, 0o4, 0o7)
    region = FactoryBot.create(:region, id: 225_672, name: 'North Manmerica')
    country = FactoryBot.create(:country, id: 2_265_721, iso_3: 'MBN', name: 'Manboneland', region: region)
    iucn_category = FactoryBot.create(:iucn_category, id: 775_677, name: 'IA')
    jurisdiction = FactoryBot.create(:jurisdiction, id: 765_677, name: 'International')
    designation = FactoryBot.create(:designation, id: 876_567, name: 'National', jurisdiction: jurisdiction)
    governance = FactoryBot.create(:governance, id: 96_767, name: 'Bone Man')
    legal_status = FactoryBot.create(:legal_status, id: 56_767, name: 'Proposed')
    management_authority = FactoryBot.create(:management_authority, name: 'Authority of Authorities')
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
      sources: [FactoryBot.create(:source)]
    }
    # Create PA
    pa = FactoryBot.create(:protected_area, pa_info_base)
    expected_response = [{:site_pid=>"555999", :attributes=>[{:title=>"Parcel ID", :value=>"555999", :is_site_pid=>true}, {:title=>"Name", :value=>"San GuillermoAAA"}, {:title=>"English Name", :value=>"San GuillermoAAA"}, {:title=>"English Designation", :value=>"National"}, {:title=>"IUCN Management Category", :value=>"IA"}, {:title=>"Status", :value=>"Proposed"}, {:title=>"Type of Designation", :value=>"International"}, {:title=>"Status Year", :value=>"2025"}, {:title=>"Governance Type", :value=>"Bone Man"}, {:title=>"Governance Subtype", :value=>"Not Reported"}, {:title=>"Management Authority", :value=>"Authority of Authorities"}, {:title=>"Management Plan", :value=>"A plan"}, {:title=>"Ownership Type", :value=>"Not Reported"}, {:title=>"Ownership Subtype", :value=>"Not Reported"}, {:title=>"International Criteria", :value=>"(ii)(iv)"}, {:title=>"Inland Waters", :value=>"Not Reported"}, {:title=>"Supplementary Information", :value=>nil}]}]

    presenter = ProtectedAreaPresenter.new(pa)
    assert_equal expected_response, presenter.current_pa_and_parcels_attributes
  end
end
