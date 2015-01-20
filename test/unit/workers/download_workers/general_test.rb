require 'test_helper'

class DownloadWorkersGeneralTest < ActiveSupport::TestCase
  test '.perform, called with type general, generates a download with all wdpa_ids' do
    Download.expects(:generate).with('general_all', {wdpa_ids: nil})

    DownloadWorkers::General.new.perform('general', 'all')
  end

  test '.perform, called with type country, generates a download with all wdpa_ids from a country' do
    country = FactoryGirl.create(:country, iso: 'US')
    pa1 = FactoryGirl.create(:protected_area, countries: [country])
    pa2 = FactoryGirl.create(:protected_area, countries: [country])

    Download.expects(:generate).with('general_US', {wdpa_ids: [pa1.wdpa_id, pa2.wdpa_id]})

    DownloadWorkers::General.new.perform('country', 'US')
  end

  test '.perform, called with type region, generates a download with all wdpa_ids from a region' do
    region = FactoryGirl.create(:region, iso: 'NA')
    country = FactoryGirl.create(:country, iso: 'US', region: region)
    pa1 = FactoryGirl.create(:protected_area, countries: [country])
    pa2 = FactoryGirl.create(:protected_area, countries: [country])

    Download.expects(:generate).with('general_NA', {wdpa_ids: [pa1.wdpa_id, pa2.wdpa_id]})

    DownloadWorkers::General.new.perform('region', 'NA')
  end
end
