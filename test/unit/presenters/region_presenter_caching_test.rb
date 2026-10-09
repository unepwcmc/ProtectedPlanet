# frozen_string_literal: true

require 'test_helper'

# RegionPresenter walked every country in the region calling #statistic -- once in
# the constructor and again in geometry_ratio, which the region page reads three
# times. Both are presenter-level concerns; Region itself is untouched.
class RegionPresenterCachingTest < ActiveSupport::TestCase
  def sql_count
    count = 0
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
      count += 1 unless payload[:name].to_s.match?(/SCHEMA|TRANSACTION/)
    end
    yield
    count
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  def region_with_countries(count)
    region = FactoryBot.create(:region, name: 'Testland')
    count.times do |i|
      country = FactoryBot.create(:country, iso_3: format('T%02d', i), name: "Country #{i}", region: region)
      FactoryBot.create(:country_statistic, country: country, polygons_count: 3, points_count: 1)
    end
    region
  end

  test 'country statistics are loaded with the countries, not one query each' do
    region = region_with_countries(5)

    # One query for the countries, one for their statistics -- not one per country.
    assert_operator sql_count { RegionPresenter.new(region) }, :<=, 3
  end

  test 'geometry_ratio is computed once however often the page reads it' do
    presenter = RegionPresenter.new(region_with_countries(5))
    presenter.geometry_ratio

    assert_equal 0, sql_count {
      presenter.chart_point_poly
      presenter.total_points_percentage
      presenter.total_polygons_percentage
    }
  end

  test 'geometry_ratio still reports the right split and handles no statistics' do
    assert_equal({ polygons: 75, points: 25 }, RegionPresenter.new(region_with_countries(4)).geometry_ratio)

    empty = FactoryBot.create(:region, name: 'Emptyland')
    assert_equal({ polygons: 0, points: 0 }, RegionPresenter.new(empty).geometry_ratio)
  end
end
