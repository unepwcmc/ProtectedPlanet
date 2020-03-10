class Search::AreasSerializer < Search::BaseSerializer
  def initialize(search, more=false)
    super(search)
    @aggregations = @search.aggregations
    @more = more
  end

  def serialize
    [
      regions,
      countries,
      sites
    ].to_json
  end

  private

  def regions
    _regions = @aggregations['region']
    _regions = _regions.first(3) unless @more
    {
      geoType: 'region',
      title: I18n.t('global.geo-types.regions'),
      total: _regions.length,
      areas: _regions.map do |region|
        {
          title: region[:identifier],
          totalAreas: "#{region[:count]} #{I18n.t('global.search.protected-areas')}" , # TODO
          url: 'url to page' # TODO
        }
      end
    }
  end

  def countries
    _countries = @aggregations['country']
    _countries = _countries.first(3) unless @more
    {
      geoType: 'country',
      title: I18n.t('global.geo-types.countries'),
      total: _countries.length,
      areas: _countries.map do |country|
        _slug = slug(country[:identifier])
        {
          countryFlag: ActionController::Base.helpers.image_url("flags/#{_slug}.svg"),
          # region: 'America', # TODO
          totalAreas: "#{country[:count]} #{I18n.t('global.search.protected-areas')}" , # TODO
          title: country[:identifier],
          url: 'url to page' # TODO
        }
      end
    }
  end

  def sites
    _sites = @results.select { |record| record.is_a?(ProtectedArea) }
    _sites = _sites.first(3) unless @more
    _total_count = @aggregations['region'].inject(0) { |sum, r| sum + r[:count] }
    {
      geoType: 'site',
      title: I18n.t('global.area-types.wdpa'), ## OR I18n.t('global.area_types.oecm')
      total: _total_count,
      areas: _sites.map do |site|
        # _countries = site.countries
        # _regions = _countries.map(&:region).map(&:name).uniq
        {
          # countries: _countries.map { |country|
          #   {
          #     title: country[:name],
          #     flag: ActionController::Base.helpers.image_url("flags/#{slug(country.name)}.svg"),
          #   }
          # },
          image: '/assets/tiles/FR?type=country&version=1', # TODO This should be a mapbox internal asset
          # region: _regions.join(','),
          title: site.name,
          url: 'url to page' # TODO
        }
      end
    }
  end

  def slug(name)
    name.underscore.gsub(' ', '-')
  end
end
