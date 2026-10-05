require 'test_helper'

# Snapshot / characterization test for the JSON contract CountrySerializer sends
# to the frontend. Its job is to catch *silent* shape or type changes across
# Rails / adapter upgrades -- e.g. the kind of numeric-cast change that turned
# raw-SQL decimals from String to BigDecimal on the 6.1 bump. Assert exact
# values AND types.
class CountrySerializerTest < ActiveSupport::TestCase
  setup do
    @country = FactoryBot.create(:country, name: 'Testland', iso_3: 'TST')
    FactoryBot.create(:country_statistic,
      country: @country,
      percentage_pa_land_cover: 10.5,
      percentage_pa_marine_cover: 20.5,
      percentage_well_connected: 30.5,
      percentage_importance: 40.5)
    FactoryBot.create(:pame_statistic,
      country: @country,
      pame_percentage_pa_land_cover: 9.1234,
      pame_percentage_pa_marine_cover: 5.5678)
  end

  test 'serialize returns the expected envelope and record shape' do
    result = CountrySerializer.new({}).serialize

    assert_equal 1, result[:page]
    assert_equal 15, result[:per_page]
    assert_equal 1, result[:total]
    assert_equal 1, result[:data].size

    assert_equal({
      'percentage_pa_land_cover'        => 10.5,
      'percentage_pa_marine_cover'      => 20.5,
      'percentage_well_connected'       => 30.5,
      'percentage_importance'           => 40.5,
      'pame_percentage_pa_land_cover'   => 9.1234,
      'pame_percentage_pa_marine_cover' => 5.5678,
      'name'                            => 'Testland',
      'iso_3'                           => 'TST'
    }, result[:data].first)
  end

  test 'numeric fields serialize as Floats, not strings' do
    record = CountrySerializer.new({}).serialize[:data].first

    assert_instance_of Float, record['percentage_well_connected']
    assert_instance_of Float, record['pame_percentage_pa_land_cover']
  end

  test 'to_json round-trips to the same structure with string keys' do
    serializer = CountrySerializer.new({})
    parsed = JSON.parse(serializer.to_json)

    assert_equal %w[page per_page data total].sort, parsed.keys.sort
    assert_equal serializer.serialize[:data].first, parsed['data'].first
  end
end
