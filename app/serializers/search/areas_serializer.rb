class Search::AreasSerializer < Search::BaseSerializer
  def initialize(search, geo_type=nil)
    super(search)
    @aggregations = @search.aggregations
    @geo_type = geo_type
  end

  def serialize
    @geo_type.present? ? send(@geo_type.pluralize) : {}
  end

  private

  def regions
    _regions = @results.regions || []

    geo_hash('region', _regions, @results.count)
  end

  def countries
    _countries = @results.countries || []

    geo_hash('country', _countries, @results.count)
  end

  def sites
    _sites = @results.protected_areas
    # Counting by governance has every PA must have one.
    # Counting by country or region is not reliable as a PA might belong to more than one country.
    _total_count = @aggregations['governance'].inject(0) { |sum, r| sum + r[:count] }

    geo_hash('site', _sites, _total_count)
  end

  def geo_hash(geo_type, areas, total=0)
    areas = areas.present? ? areas.first(9) : []
    geo_type_locale = "geo-types.#{geo_type.pluralize}"
    {
      geoType: geo_type,
      title: I18n.t("global.#{geo_type_locale}"),
      total: total || areas.length,
      totalPages: total_pages(total),
      areas: areas_ary(geo_type, areas)
    }
  end

  def areas_ary(geo_type, areas)
    return [] if areas.blank?
    areas.map { |a| send("#{geo_type}_hash", a) }
  end

  def region_hash(region)
    {
      title: region.name,
      totalAreas: "#{areas_count(region)} #{I18n.t('search.protected-areas')}",
      url: region_path(iso: region.iso),
      image: ApplicationController.helpers.region_cover(region)
    }
  end

  def country_hash(country)
    {
      countryFlag: ApplicationController.helpers.flag_url(country.iso_3),
      totalAreas: "#{areas_count(country)} #{I18n.t('search.protected-areas')}",
      title: country.name,
      url: country_path(iso: country.iso_3),
      image: ApplicationController.helpers.country_cover(country)
    }
  end

  def site_hash(site)
    {
      image: ApplicationController.helpers.protected_area_cover(site),
      title: site.name,
      url: protected_area_path(site.site_id)
    }
  end

  DEFAULT_PAGE_SIZE = 9.0.freeze
  def total_pages(items_no)
    (items_no / DEFAULT_PAGE_SIZE).ceil
  end

  def areas_count(model)
    ApplicationController.helpers.commaify(model.protected_areas.count)
  end
end
