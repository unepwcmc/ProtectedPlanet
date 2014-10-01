require 'test_helper'

class DownloadGeneratorTest < ActiveSupport::TestCase
  test '#generate generates downloads for all PAs and each country' do
    north_america = FactoryGirl.create(:region, iso: 'NA')
    asia = FactoryGirl.create(:region, iso: 'AS')

    st_lucia = FactoryGirl.create(:country, iso_3: 'STL', region: north_america)
    samoa = FactoryGirl.create(:country, iso_3: 'SAM', region: north_america)
    kenya = FactoryGirl.create(:country, iso_3: 'KEN', region: asia)

    FactoryGirl.create(:protected_area, countries: [st_lucia, kenya], wdpa_id: 1)
    FactoryGirl.create(:protected_area, countries: [samoa], wdpa_id: 555555123)

    Download.expects(:generate).with('all')

    Download.expects(:generate).with(st_lucia.iso_3, wdpa_ids: [1], for_import: true)
    Download.expects(:generate).with(kenya.iso_3, wdpa_ids: [1], for_import: true)
    Download.expects(:generate).with(samoa.iso_3, wdpa_ids: [555555123], for_import: true)

    Download.expects(:generate).with(north_america.iso, wdpa_ids: [1, 555555123], for_import: true)
    Download.expects(:generate).with(asia.iso, wdpa_ids: [1], for_import: true)

    Wdpa::DownloadGenerator.generate
  end
end

