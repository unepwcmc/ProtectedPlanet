require 'test_helper'

class ProtectedAreaParcelTest < ActiveSupport::TestCase
  test ".save creates a slug attribute consisting of parameterized name and designation" do
    designation = FactoryGirl.create(:designation, name: 'Protected Area')
    protected_area = FactoryGirl.create(:protected_area, site_id: 123, name: 'Finn and Jake Land', designation: designation)
    parcel = FactoryGirl.create(:protected_area_parcel,
      site_id: protected_area.site_id,
      site_pid: '123_A',
      name: 'Finn and Jake Land',
      designation: designation
    )
    assert_equal '123-123-a-finn-and-jake-land-protected-area', parcel.slug
  end

  test "parcel can have green_list_status" do
    gl = FactoryGirl.create(:green_list_status, gl_status: 'Green Listed')
    pa = FactoryGirl.create(:protected_area, site_id: 456)
    parcel = FactoryGirl.create(:protected_area_parcel, site_id: pa.site_id, site_pid: '456_A', green_list_status: gl)
    assert_equal gl.id, parcel.green_list_status_id
    assert parcel.green_list_status.present?
  end
end
