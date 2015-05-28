require 'test_helper'

class DownloadGeneratorTest < ActiveSupport::TestCase
  test '#generate generates downloads for all PAs and each country' do
    st_lucia = FactoryGirl.create(:country, iso_3: 'STL')
    samoa = FactoryGirl.create(:country, iso_3: 'SAM')
    kenya = FactoryGirl.create(:country, iso_3: 'KEN')

    FactoryGirl.create(:protected_area, countries: [st_lucia, kenya], wdpa_id: 1)
    FactoryGirl.create(:protected_area, countries: [samoa], wdpa_id: 555555123)

    DownloadWorkers::General.expects(:perform_async).with(:general, 'all', for_import: true)

    DownloadWorkers::General.expects(:perform_async).with(:country, st_lucia.iso_3, for_import: true)
    DownloadWorkers::General.expects(:perform_async).with(:country, kenya.iso_3, for_import: true)
    DownloadWorkers::General.expects(:perform_async).with(:country, samoa.iso_3, for_import: true)

    Wdpa::DownloadGenerator.generate
  end

  test '#generate, called with argument false, performs the generation not for import' do
    st_lucia = FactoryGirl.create(:country, iso_3: 'STL')

    DownloadWorkers::General.expects(:perform_async).with(:general, 'all', for_import: false)
    DownloadWorkers::General.expects(:perform_async).with(:country, st_lucia.iso_3, for_import: false)

    Wdpa::DownloadGenerator.generate false
  end
end
