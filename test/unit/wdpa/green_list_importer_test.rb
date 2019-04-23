require 'test_helper'

class TestWdpaMarineStatsImporter < ActiveSupport::TestCase
  test "#import update sites to be green list" do
    wdpa_ids = [1,2,3]
    wdpa_ids.each do |wdpa_id|
      FactoryGirl.create(:protected_area, wdpa_id: wdpa_id)
    end

    green_list_sites = wdpa_ids.slice(1,2)
    csv_content = [['site', 'status', 'date'],
                   [green_list_sites.first, 'Candidate', '2018'],
                   [green_list_sites.second, 'Green Listed', '2017']]
    CSV.stubs(:read).returns(csv_content)

    Wdpa::GreenListImporter.import
    green_list_pas = ProtectedArea.where(is_green_list: true).count
    assert_equal green_list_pas, 2
  end
end
