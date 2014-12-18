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

    DownloadWorkers::General.expects(:perform_async).with(:general, 'all', for_import: true)

    DownloadWorkers::General.expects(:perform_async).with(:country, st_lucia.iso_3, for_import: true)
    DownloadWorkers::General.expects(:perform_async).with(:country, kenya.iso_3, for_import: true)
    DownloadWorkers::General.expects(:perform_async).with(:country, samoa.iso_3, for_import: true)

    DownloadWorkers::General.expects(:perform_async).with(:region, north_america.iso, for_import: true)
    DownloadWorkers::General.expects(:perform_async).with(:region, asia.iso, for_import: true)

    Wdpa::DownloadGenerator.generate
  end
end

