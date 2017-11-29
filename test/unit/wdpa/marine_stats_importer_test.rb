require 'test_helper'

class TestWdpaMarineStatsImporter < ActiveSupport::TestCase
  test "#import imports the marine stats" do
    stats = Wdpa::MarineStatsImporter.import

    assert_equal(stats, $redis.hgetall('wdpa_marine_stats'))
  end
end
