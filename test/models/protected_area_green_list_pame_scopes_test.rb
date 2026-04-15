require 'test_helper'

class ProtectedAreaGreenListPameScopesTest < ActiveSupport::TestCase
  test 'pas_with_green_list_on_self_only returns PAs with green_list_status on self' do
    status = FactoryGirl.create(:green_list_status)
    gl_pa = FactoryGirl.create(:protected_area, green_list_status: status)
    non_gl_pa = FactoryGirl.create(:protected_area, green_list_status: nil)

    result_ids = ProtectedArea.pas_with_green_list_on_self_only.pluck(:id)

    assert_includes result_ids, gl_pa.id
    refute_includes result_ids, non_gl_pa.id
  end

  test 'pas_with_green_list_on_self_or_any_parcel includes PAs with parcel-only green list' do
    status = FactoryGirl.create(:green_list_status)
    pa_with_gl_parcel = FactoryGirl.create(:protected_area, green_list_status: nil)
    FactoryGirl.create(:protected_area_parcel, protected_area: pa_with_gl_parcel, green_list_status: status)

    pa_without_gl = FactoryGirl.create(:protected_area, green_list_status: nil)

    result_ids = ProtectedArea.pas_with_green_list_on_self_or_any_parcel.pluck(:id)

    assert_includes result_ids, pa_with_gl_parcel.id
    refute_includes result_ids, pa_without_gl.id
  end

  test 'pas_with_pame_on_self_only returns PAs with PAME on self' do
    pa_with_pame = FactoryGirl.create(:protected_area)
    pa_without_pame = FactoryGirl.create(:protected_area)

    FactoryGirl.create(:pame_evaluation, protected_area: pa_with_pame)

    result_ids = ProtectedArea.pas_with_pame_on_self_only.pluck(:id)

    assert_includes result_ids, pa_with_pame.id
    refute_includes result_ids, pa_without_pame.id
  end

  test 'pas_with_pame_on_self_or_any_parcel includes PAs with parcel-only PAME' do
    pa = FactoryGirl.create(:protected_area)
    FactoryGirl.create(:protected_area_parcel, protected_area: pa)
    FactoryGirl.create(:pame_evaluation, protected_area: nil, protected_area_parcel: pa.protected_area_parcels.first)

    other_pa = FactoryGirl.create(:protected_area)

    result_ids = ProtectedArea.pas_with_pame_on_self_or_any_parcel.pluck(:id)

    assert_includes result_ids, pa.id
    refute_includes result_ids, other_pa.id
  end

  test 'pa_or_any_its_parcels_is_greenlisted is true when PA or parcel is greenlisted' do
    status = FactoryGirl.create(:green_list_status, gl_status: 'Green Listed')
    pa = FactoryGirl.create(:protected_area, green_list_status: nil)
    parcel = FactoryGirl.create(:protected_area_parcel, protected_area: pa, green_list_status: status)

    assert pa.pa_or_any_its_parcels_is_greenlisted
  end

  test 'pa_or_any_its_parcels_is_greenlist_candidate is true when any parcel is candidate' do
    status = FactoryGirl.create(:green_list_status, gl_status: 'Candidate')
    pa = FactoryGirl.create(:protected_area, green_list_status: nil)
    FactoryGirl.create(:protected_area_parcel, protected_area: pa, green_list_status: status)

    assert pa.pa_or_any_its_parcels_is_greenlist_candidate
  end
end

