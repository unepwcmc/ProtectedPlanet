# frozen_string_literal: true

# Every schema.org/JSON-LD node the site emits. Controllers decide WHICH node a
# page is and supply the page's own name and description; the shape of the graph
# -- what types exist, which fields they carry, what gets omitted -- lives here.
#
# URLs are injected rather than built from route helpers: default_url_options
# appends ?locale=en to any route without a :locale segment (/:id, the protected
# area page, has none), so a route helper would disagree with the
# <link rel="canonical"> on the same page.
class StructuredDataPresenter
  CONTEXT = 'https://schema.org'

  def initialize(canonical_url:, site_url:, logo_url:)
    @canonical_url = canonical_url
    @site_url = site_url
    @logo_url = logo_url
  end

  # Only the home page IS the WebSite, and its url must be the bare domain --
  # every other path gets a #webpage instead, so no page repeats the site node
  # under its own url.
  def website
    node(
      'WebSite',
      name: site_name,
      url: site_url,
      description: site_description,
      publisher: publisher
    )
  end

  # The fallback for anything that does not describe a specific thing: CMS pages,
  # search, error pages. name/description come from the page's meta; the brand
  # suffix the <title> tag carries is not wanted in a schema.org name, hence the
  # plain site-name fallback.
  def webpage(name: nil, description: nil)
    node(
      'WebPage',
      name: name.presence || site_name,
      url: canonical_url,
      description: description.presence || site_description,
      isPartOf: { '@type': 'WebSite', name: site_name, url: site_url },
      publisher: publisher
    )
  end

  # A protected area is a Place, not a WebSite -- which is what all of these pages
  # claimed to be. Only fields backed by data already loaded (or a single indexed
  # lookup) are included; a page nobody can describe is worse than a short one.
  def protected_area(protected_area, countries:, description:)
    node(
      'Place',
      name: protected_area.name,
      alternateName: alternate_name(protected_area),
      description: description,
      url: canonical_url,
      address: address(countries),
      geo: geo(protected_area),
      additionalProperty: place_properties(protected_area)
    )
  end

  # An administrative area, not the website. containsPlace is deliberately absent:
  # a country holds thousands of protected areas and enumerating them here would
  # be a huge payload that the sitemap already covers properly.
  def country(country, description:)
    node(
      'Country',
      name: country.name,
      url: canonical_url,
      description: description,
      identifier: [
        property_value('ISO 3166-1 alpha-3', country.iso_3),
        property_value('ISO 3166-1 alpha-2', country.iso)
      ].compact
    )
  end

  def region(region, description:)
    node('Place', name: region.name, url: canonical_url, description: description)
  end

  private

  attr_reader :canonical_url, :site_url, :logo_url

  # compact, not deep_compact: a nil at the top level is a field this page cannot
  # describe, and every nested hash is built whole or not at all.
  def node(type, attributes)
    { '@context': CONTEXT, '@type': type }.merge(attributes).compact
  end

  def publisher
    {
      '@type': 'Organization',
      name: site_name,
      url: site_url,
      logo: logo_url
    }
  end

  # Omitted when it matches name, which it does for most sites -- repeating the
  # same string as an alternate name tells a consumer nothing.
  def alternate_name(protected_area)
    original_name = protected_area.original_name.presence
    return if original_name.nil? || original_name == protected_area.name

    original_name
  end

  def address(countries)
    return if countries.empty?

    {
      '@type': 'PostalAddress',
      addressCountry: countries.map(&:iso_3)
    }
  end

  # the_geom_latitude/longitude are string columns on the record, so this costs no
  # query and no PostGIS call.
  def geo(protected_area)
    latitude = protected_area.the_geom_latitude
    longitude = protected_area.the_geom_longitude
    return if latitude.blank? || longitude.blank?

    { '@type': 'GeoCoordinates', latitude: latitude, longitude: longitude }
  end

  def place_properties(protected_area)
    properties = {
      'WDPA ID' => protected_area.site_id,
      'Designation' => protected_area.designation&.name,
      'IUCN Management Category' => protected_area.iucn_category&.name,
      'Reported area (km²)' => protected_area.reported_area&.to_f&.round(2)
    }

    properties.filter_map { |name, value| property_value(name, value) }.presence
  end

  def property_value(name, value)
    return if value.blank?

    { '@type': 'PropertyValue', name: name, value: value }
  end

  def site_name
    I18n.t('meta.site.name')
  end

  def site_description
    I18n.t('meta.site.description')
  end
end
