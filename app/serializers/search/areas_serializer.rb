class Search::AreasSerializer < Search::BaseSerializer
  def initialize(search)
    super(search)
    @aggregations = @search.aggregations
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
    _regions = @aggregations['region'].map { |obj| obj[:identifier] }
    {
      geoType: 'region',
      title: I18n.t('global.geo-types.regions'),
      total: _regions.length,
      areas: _regions.map do |region|
        {
          title: region,
          url: 'url to page' # TODO
        }
      end
    }
  end

  def countries
    _countries = @aggregations['country']
    {
      geoType: 'country',
      title: I18n.t('global.geo-types.countries'),
      total: _countries.length,
      areas: _countries.map do |country|
        _slug = slug(country[:identifier])
        {
          areas: country[:count],
          countryFlag: ActionController::Base.helpers.image_url("flags/#{_slug}.svg"),
          region: 'America', # TODO
          title: country[:identifier],
          url: 'url to page' # TODO
        }
      end
    }
  end

  def sites
    _sites = @results.select { |record| record.is_a?(ProtectedArea) }
    {
      geoType: 'site',
      title: I18n.t('global.area-types.wdpa'), ## OR I18n.t('global.area_types.oecm')
      total: _sites.count,
      areas: _sites.map do |site|
        _countries = site.countries
        _regions = _countries.map(&:region).map(&:name).uniq
        {
          countries: _countries.map { |country| 
            {
              title: country[:name],
              flag: ActionController::Base.helpers.image_url("flags/#{slug(country.name)}.svg"),
            }
          },
          image: '/assets/tiles/FR?type=country&version=1', # TODO This should be a mapbox internal asset
          region: _regions.join(','),
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
