require 'test_helper'

class ProtectedAreaPresenterGreenListTest < ActiveSupport::TestCase
  test 'greenlist_status_by_pa_and_all_its_parcels returns one affiliation per greenlisted parcel' do
    status = FactoryGirl.create(:green_list_status, gl_status: 'Green Listed', gl_link: 'https://example.com/gl/1')
    pa = FactoryGirl.create(:protected_area, green_list_status: nil)
    FactoryGirl.create(:protected_area_parcel, protected_area: pa, site_pid: '123_1', green_list_status: status, name: 'Parcel 1')
    FactoryGirl.create(:protected_area_parcel, protected_area: pa, site_pid: '123_2', green_list_status: nil, name: 'Parcel 2')

    presenter = ProtectedAreaPresenter.new(pa)
    affiliations = presenter.send(:greenlist_status_by_pa_and_all_its_parcels)

    assert_equal 1, affiliations.size
    aff = affiliations.first
    assert_equal '123_1', aff[:site_pid]
    assert_equal 'greenlist', aff[:affiliation]
    assert_equal 'Green Listed', aff[:type]
    assert_equal status.gl_link, aff[:link_url]
    assert_equal status.gl_expiry.year, aff[:date], 'Frontend should receive gl_expiry as a 4-digit year'
    assert aff[:image_url].include?('green-list')
  end
end

