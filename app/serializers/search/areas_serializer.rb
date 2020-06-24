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
    _regions = @aggregations['region']

    geo_hash('region', paginate(_regions), _regions.length)
  end

  def countries
    _countries = @aggregations['country']

    geo_hash('country', paginate(_countries), _countries.length)
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
    geo_type_locale = geo_type == 'site' ? 'area-types.wdpa' : "geo-types.#{geo_type.pluralize}"
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
      title: region[:label],
      totalAreas: "#{region[:count]} #{I18n.t('search.protected-areas')}",
      url: region_path(iso: region[:identifier])
    }
  end

  def country_hash(country)
    _slug = slug(country[:label])
    {
      countryFlag: ActionController::Base.helpers.image_url("flags/#{_slug}.svg"),
      totalAreas: "#{country[:count]} #{I18n.t('search.protected-areas')}",
      title: country[:label],
      url: country_path(iso: country[:identifier])
    }
  end

  def site_hash(site)
    {
      image: '/assets/tiles/FR?type=country&version=1', # TODO This should be a mapbox internal asset
      title: site.name,
      url: protected_area_path(site.wdpa_id)
    }
  end

  def slug(name)
    name.underscore.gsub(' ', '-')
  end

  DEFAULT_PAGE_SIZE = 9.0.freeze
  def total_pages(items_no)
    (items_no / DEFAULT_PAGE_SIZE).ceil
  end
end
