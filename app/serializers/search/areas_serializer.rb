class Search::AreasSerializer < Search::BaseSerializer
  def initialize(search, geo_type=nil)
    super(search)
    @aggregations = @search.aggregations
    @geo_type = geo_type
  end

  def serialize
    if @geo_type
      areas = @geo_type == 'site' ? @results.protected_areas : paginate(@aggregations[@geo_type])
      return areas_ary(@geo_type, areas).to_json
    end

    [
      regions,
      countries,
      sites
    ].to_json
  end

  private

  def regions
    _regions = @aggregations['region']

    geo_hash('region', _regions, _regions.length)
  end

  def countries
    _countries = @aggregations['country']

    geo_hash('country', _countries, _countries.length)
  end

  def sites
    _sites = @results.protected_areas
    _sites = _sites
    _total_count = @aggregations['region'].inject(0) { |sum, r| sum + r[:count] }

    geo_hash('site', _sites, _total_count)
  end

  def geo_hash(geo_type, areas, total=nil)
    areas = areas.present? ? areas.first(3) : []
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
      title: region[:identifier],
      totalAreas: "#{region[:count]} #{I18n.t('global.search.protected-areas')}" , # TODO
      url: 'url to page' # TODO
    }
  end

  def country_hash(country)
    _slug = slug(country[:identifier])
    {
      countryFlag: ActionController::Base.helpers.image_url("flags/#{_slug}.svg"),
      # region: 'America', # TODO
      totalAreas: "#{country[:count]} #{I18n.t('global.search.protected-areas')}" , # TODO
      title: country[:identifier],
      url: 'url to page' # TODO
    }
  end

  def site_hash(site)
    {
      image: '/assets/tiles/FR?type=country&version=1', # TODO This should be a mapbox internal asset
      title: site.name,
      url: 'url to page' # TODO
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
