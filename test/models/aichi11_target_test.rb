require 'test_helper'

class Aichi11TargetTest < ActiveSupport::TestCase
  test 'it only creates one instance' do
    FactoryGirl.create(:aichi11_target)

    assert_raise(ActiveRecord::RecordNotUnique) { FactoryGirl.create(:aichi11_target) }
  end

  test 'it imports and saves stats from API' do
    data = { importance_global: 12.15 }
    Stats::CountryStatisticsApi.stubs(:global_stats_for_import).returns(data)

    assert_equal Aichi11Target.instance.importance_global, 12.15
  end

  test 'it reads targets from file' do
    Stats::CountryStatisticsApi.stubs(:global_stats_for_import).returns({})

    Aichi11Target.expects(:aichi11_target_csv_path).returns(
      Rails.root.join('lib/data/seeds/aichi11_targets.csv')
    )
    assert_equal(Aichi11Target.instance.importance_global, 17)
  end
end
