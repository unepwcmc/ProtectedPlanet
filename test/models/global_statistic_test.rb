# frozen_string_literal: true

require 'test_helper'

class GlobalStatisticTest < ActiveSupport::TestCase
  test 'download_csv builds rows from the live record and the descriptions file' do
    GlobalStatistic.instance.update!(total_protected_areas: 312_919, global_ocean_percentage: 61)

    csv = CSV.parse(GlobalStatistic.download_csv, headers: true)

    total_row = csv.find { |row| row['type'] == 'total_protected_areas' }
    assert_equal 'number of protected areas', total_row['description']
    assert_equal '312919', total_row['value']

    methodology_row = csv.find { |row| row['description'].to_s.start_with?('methodology used') }
    assert methodology_row
    assert_nil methodology_row['type']
    assert_nil methodology_row['value']
  end

  test 'download_csv includes the high seas OECM stats' do
    GlobalStatistic.instance.update!(
      high_seas_oecms_coverage_percentage: 0.208,
      high_seas_oecms_coverage_area: 462_847,
      high_seas_oecms_pas_coverage_percentage: 1.656,
      high_seas_oecms_pas_coverage_area: 3_684_542
    )

    csv = CSV.parse(GlobalStatistic.download_csv, headers: true)
    values = csv.each_with_object({}) { |row, hash| hash[row['type']] = row['value'] }

    assert_equal '0.208', values['high_seas_oecms_coverage_percentage']
    assert_equal '462847', values['high_seas_oecms_coverage_area']
    assert_equal '1.656', values['high_seas_oecms_pas_coverage_percentage']
    assert_equal '3684542', values['high_seas_oecms_pas_coverage_area']
  end

  test 'download_csv reflects updated values after cache key changes' do
    GlobalStatistic.instance.update!(total_protected_areas: 1)
    first = GlobalStatistic.download_csv

    GlobalStatistic.instance.update!(total_protected_areas: 2)
    second = GlobalStatistic.download_csv

    refute_equal first, second
  end

  test 'download_csv_filename uses the current release label as a month/year timestamp' do
    Release.stubs(:current_label).returns('Jul2026')

    assert_equal 'global_statistics_2026-07-01.csv', GlobalStatistic.download_csv_filename
  end

  test 'download_csv_filename falls back to the current date when there is no release label' do
    Release.stubs(:current_label).returns(nil)

    travel_to Time.zone.local(2026, 7, 15) do
      assert_equal 'global_statistics_2026-07-01.csv', GlobalStatistic.download_csv_filename
    end
  end
end
