require 'test_helper'

class DownloadGeneratorTest < ActiveSupport::TestCase
  test '#generate generates downloads for all PAs and each country' do
    st_lucia = FactoryGirl.create(:country, iso_3: 'STL')
    samoa = FactoryGirl.create(:country, iso_3: 'SAM')
    kenya = FactoryGirl.create(:country, iso_3: 'KEN')

    FactoryGirl.create(:protected_area, countries: [st_lucia, kenya], wdpa_id: 1)
    FactoryGirl.create(:protected_area, countries: [samoa], wdpa_id: 555555123)

    Download.expects(:generate).with('all')
    Download.expects(:generate).with(st_lucia.iso_3, [1])
    Download.expects(:generate).with(kenya.iso_3, [1])
    Download.expects(:generate).with(samoa.iso_3, [555555123])

    Wdpa::DownloadGenerator.generate
  end
end
