# frozen_string_literal: true

require 'test_helper'

class TestGreenListImporter < ActiveSupport::TestCase
  def before_setup
    super

    wdpa_ids = [1, 2, 3]
    wdpa_ids.each do |wdpa_id|
      FactoryGirl.create(:protected_area, wdpa_id: wdpa_id)
    end

    # multiple_yields from mocha expects multiple arrays,
    # an array for each row
    csv_content = [
      [{
        'wdpaid' => 1,
        'status' => 'Green Listed',
        'expiry_date' => Date.today
      }],
      [{
        'wdpaid' => 2,
        'status' => 'Candidate',
        'expiry_date' => Date.today
      }]
    ]

    CSV.stubs(:foreach).with("#{Rails.root}/lib/data/seeds/test_green_list_sites.csv", headers: true)
      .multiple_yields(*csv_content)
  end

  test '#import updates sites to be green list' do
    Wdpa::GreenListImporter.import
    green_list_pas = ProtectedArea.where.not(green_list_status_id: nil).count

    assert_equal green_list_pas, 2
  end

  test '#import creates correct number of GreenListStatus records' do
    Wdpa::GreenListImporter.import

    assert_equal GreenListStatus.count, 2
  end

  test '#import creates GreenListStatus records with correct status' do
    Wdpa::GreenListImporter.import
    gls_1 = ProtectedArea.find_by(wdpa_id: 1).green_list_status
    gls_2 = ProtectedArea.find_by(wdpa_id: 2).green_list_status

    assert_equal gls_1.status, 'Green Listed'
    assert_equal gls_2.status, 'Candidate'
  end

  test '#import creates GreenListStatus records with correct expiry date' do
    Wdpa::GreenListImporter.import
    gls_1 = ProtectedArea.find_by(wdpa_id: 1).green_list_status
    gls_2 = ProtectedArea.find_by(wdpa_id: 2).green_list_status

    assert_equal gls_1.expiry_date, Date.today
    assert_equal gls_2.expiry_date, Date.today
  end
end
