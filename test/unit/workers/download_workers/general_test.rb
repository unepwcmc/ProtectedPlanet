require 'test_helper'

class DownloadWorkersGeneralTest < ActiveSupport::TestCase
  def setup
    Wdpa::S3.stubs(:current_wdpa_identifier).returns('Jun2015')
  end

  test '.perform, called with type general, generates a download with all site_ids' do
    Download.expects(:generate).with('WDPA_Jun2015', { site_ids: nil })

    DownloadWorkers::General.new.perform('general', 'all')
  end

  test '.perform, called with type country, generates a download with all site_ids from a country' do
    country = FactoryGirl.create(:country, iso_3: 'USA')
    pa1 = FactoryGirl.create(:protected_area, countries: [country])
    pa2 = FactoryGirl.create(:protected_area, countries: [country])

    Download.expects(:generate).with('WDPA_Jun2015_USA', { site_ids: [pa1.site_id, pa2.site_id] })

    DownloadWorkers::General.new.perform('country', 'USA')
  end

  test '.perform, called with type region, generates a download with all site_ids from a region' do
    region = FactoryGirl.create(:region, iso: 'NA')
    country = FactoryGirl.create(:country, iso_3: 'USA', region: region)
    pa1 = FactoryGirl.create(:protected_area, countries: [country])
    pa2 = FactoryGirl.create(:protected_area, countries: [country])

    Download.expects(:generate).with('WDPA_Jun2015_NA', { site_ids: [pa1.site_id, pa2.site_id] })

    DownloadWorkers::General.new.perform('region', 'NA')
  end
end
