require 'test_helper'

class TestDopaImporter < ActiveSupport::TestCase
  test "#import DOPA sites" do
    DOPA_LIST = "#{Rails.root}/lib/data/seeds/dopa4_pas_list.csv"

    wdpa_ids = [1,2,3]
    wdpa_ids.each do |wdpa_id|
      FactoryGirl.create(:protected_area, wdpa_id: wdpa_id)
    end

    Wdpa::DopaImporter.import(DOPA_LIST)

    assert_equal 3, ProtectedArea.where(is_dopa: true).count   
  end

  test "#skip DOPA sites which don't have a record in the DB" do 
    DOPA_LIST = "#{Rails.root}/test/unit/wdpa/csv_mocks/dopa_test.csv"

    wdpa_ids = [1,2,4]
    wdpa_ids.each do |wdpa_id|
      FactoryGirl.create(:protected_area, wdpa_id: wdpa_id)
    end

    Wdpa::DopaImporter.import(DOPA_LIST)

    assert_equal 0, ProtectedArea.where(is_dopa: true).count   
  end

end
