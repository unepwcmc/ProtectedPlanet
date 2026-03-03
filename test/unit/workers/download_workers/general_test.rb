require 'test_helper'

class DownloadWorkersGeneralTest < ActiveSupport::TestCase
  def setup
    Wdpa::S3.stubs(:current_wdpa_identifier).returns('Jun2015')
  end

  test '.perform, called with type general, generates a download with all site_ids' do
    Download.expects(:generate).with('WDPA_Jun2015', { site_selection: nil })

    DownloadWorkers::General.new.perform('general', 'all')
  end

  test '.perform, called with type country, generates a download with all site_ids from a country' do
    country = FactoryGirl.create(:country, iso_3: 'USA')

    Download.expects(:generate).with('WDPA_Jun2015_USA', {
      site_selection: {
        iso3: [country.iso_3],
        site_ids: nil,
        site_id_and_pid_pairs: nil,
        site_types: nil
      }
    })

    DownloadWorkers::General.new.perform('country', 'USA')
  end

  test '.perform, called with type region, generates a download with all site_ids from a region' do
    region = FactoryGirl.create(:region, iso: 'NA')
    FactoryGirl.create(:country, iso_3: 'USA', region: region)

    Download.expects(:generate).with('WDPA_Jun2015_NA', {
      site_selection: {
        iso3: region.countries.pluck(:iso_3),
        site_ids: nil,
        site_id_and_pid_pairs: nil,
        site_types: nil
      }
    })

    DownloadWorkers::General.new.perform('region', 'NA')
  end
end
