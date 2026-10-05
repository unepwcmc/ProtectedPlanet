# frozen_string_literal: true

require 'test_helper'

# The per-page JSON-LD nodes. Plain structs stand in for the records: the
# presenter only reads attributes off them, so this needs no database.
class StructuredDataPresenterTest < ActiveSupport::TestCase
  Area = Struct.new(:name, :original_name, :site_id, :designation, :iucn_category,
                    :reported_area, :the_geom_latitude, :the_geom_longitude,
                    keyword_init: true)
  Named = Struct.new(:name)
  Place = Struct.new(:name, :iso, :iso_3, keyword_init: true)

  def setup
    @presenter = StructuredDataPresenter.new(
      canonical_url: 'https://example.test/123',
      site_url: 'https://example.test/',
      logo_url: 'https://example.test/assets/social.png'
    )
  end

  def full_area
    Area.new(
      name: 'Kruger National Park',
      original_name: 'Krugerwildtuin',
      site_id: 873,
      designation: Named.new('National Park'),
      iucn_category: Named.new('II'),
      reported_area: 19_485.123,
      the_geom_latitude: '-23.99',
      the_geom_longitude: '31.55'
    )
  end

  test 'a protected area is a Place carrying its identifiers, address and coordinates' do
    data = @presenter.protected_area(full_area, countries: [Place.new(iso_3: 'ZAF')], description: 'Explore Kruger')

    assert_equal 'Place', data[:'@type']
    assert_equal 'https://schema.org', data[:'@context']
    assert_equal 'Kruger National Park', data[:name]
    assert_equal 'Krugerwildtuin', data[:alternateName]
    assert_equal 'https://example.test/123', data[:url]
    assert_equal({ '@type': 'PostalAddress', addressCountry: ['ZAF'] }, data[:address])
    assert_equal({ '@type': 'GeoCoordinates', latitude: '-23.99', longitude: '31.55' }, data[:geo])
    assert_equal ['WDPA ID', 'Designation', 'IUCN Management Category', 'Reported area (km²)'],
      data[:additionalProperty].map { |property| property[:name] }
    # Rounded to two places, not the raw float.
    assert_equal 19_485.12, data[:additionalProperty].last[:value]
    # A Place is not published by anyone -- publisher belongs to the site nodes.
    assert_not data.key?(:publisher)
  end

  test 'a protected area omits an alternate name that just repeats the name' do
    area = full_area
    area.original_name = area.name

    assert_not @presenter.protected_area(area, countries: [], description: 'x').key?(:alternateName)
  end

  test 'a protected area omits every field it has no data for' do
    area = Area.new(name: 'Unnamed reserve', site_id: 1)
    data = @presenter.protected_area(area, countries: [], description: 'x')

    assert_not data.key?(:alternateName)
    assert_not data.key?(:address)
    assert_not data.key?(:geo)
    assert_equal ['WDPA ID'], data[:additionalProperty].map { |property| property[:name] }
  end

  test 'a country is a Country with its ISO codes as identifiers' do
    data = @presenter.country(Place.new(name: 'South Africa', iso: 'ZA', iso_3: 'ZAF'), description: 'Explore ZA')

    assert_equal 'Country', data[:'@type']
    assert_equal 'South Africa', data[:name]
    assert_equal 'https://example.test/123', data[:url]
    assert_equal %w[ZAF ZA], data[:identifier].map { |identifier| identifier[:value] }
  end

  test 'a country drops an ISO code it does not have' do
    data = @presenter.country(Place.new(name: 'Kosovo', iso_3: 'XKX'), description: 'x')

    assert_equal %w[XKX], data[:identifier].map { |identifier| identifier[:value] }
  end

  test 'a region is a Place at the page url' do
    data = @presenter.region(Place.new(name: 'Africa'), description: 'Explore Africa')

    assert_equal 'Place', data[:'@type']
    assert_equal 'Africa', data[:name]
    assert_equal 'https://example.test/123', data[:url]
    assert_equal 'Explore Africa', data[:description]
  end

  test 'the site nodes name the publisher and its logo' do
    publisher = {
      '@type': 'Organization',
      name: I18n.t('meta.site.name'),
      url: 'https://example.test/',
      logo: 'https://example.test/assets/social.png'
    }

    assert_equal publisher, @presenter.website[:publisher]
    assert_equal publisher, @presenter.webpage[:publisher]
  end
end
