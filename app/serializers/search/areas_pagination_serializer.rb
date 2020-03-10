class Search::AreasPaginationSerializer < Search::BaseSerializer
  def initialize(search, geo_type)
    super(search)
    @geo_type = geo_type
  end

  def serialize
    send(@geo_type.pluralize).to_json
  end

  private

  def regions
    _regions = paginate(@search.aggregations['region'])
    _regions.map do |region|
      {
        title: region[:identifier],
        totalAreas: "#{region[:count]} #{I18n.t('global.search.protected-areas')}",
        url: 'url to page' ## TODO
      }
    end
  end

  def countries
    _countries = paginate(@search.aggregations['country'])
    _countries.map do |country|
      _slug = slug(country[:identifier])
      {
        countryFlag: ActionController::Base.helpers.image_url("flags/#{_slug}.svg"),
        # region: 'America', # TODO
        totalAreas: "#{country[:count]} #{I18n.t('global.search.protected-areas')}" , # TODO
        title: country[:identifier],
        url: 'url to page' # TODO
      }
    end
  end

  def sites
    #Pagination is already done by the Seach module
    _sites = @search.results.protected_areas
    _sites.map do |site|
      {
        image: '/assets/tiles/FR?type=country&version=1', # TODO This should be a mapbox internal asset
        title: site.name,
        url: 'url to page' # TODO
      }
    end
  end

  def slug(name)
    name.underscore.gsub(' ', '-')
  end

  def paginate(items)
    size = @search.options[:size]
    page = @search.options[:page]
    offset = size * (page - 1)
    last_item = size * page - 1

    items[offset..last_item].presence || []
  end
end
