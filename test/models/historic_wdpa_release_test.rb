require_relative '../test_helper'

class HistoricWdpaReleaseTest < ActiveSupport::TestCase

  def test_fixtures_validity
    HistoricWdpaRelease.all.each do |historic_wdpa_release|
      assert historic_wdpa_release.valid?, historic_wdpa_release.errors.inspect
    end
  end

  def test_validation
    historic_wdpa_release = HistoricWdpaRelease.new
    assert historic_wdpa_release.invalid?
    assert_equal [:year, :month, :url], historic_wdpa_release.errors.keys
  end

  def test_creation
    assert_difference 'HistoricWdpaRelease.count' do
      HistoricWdpaRelease.create(
        :url => 'test url',
        :month => 11,
        :year => 2016,
      )
    end
  end

end