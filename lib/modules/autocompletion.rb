module Autocompletion
  AUTOCOMPLETION_KEY = "autocompletion".freeze
  IDENTIFIER_FIELDS = {
    'protected_area' => :wdpa_id,
    'country' => :iso_3,
    'region' => :iso
  }.freeze

  def self.lookup(term, db_type='wdpa', search_index=Search::PA_INDEX)
    search = Search.search(term.downcase, get_filters(db_type), search_index)

    results = search.results.objects.values.compact.flatten

    results.map do |result|
      name = result.name
      type = result.class.name.underscore
      identifier = result.send(identifier_field(type))

      geom_type = result.is_a?(ProtectedArea) ? result.the_geom.geometry_type.to_s : 'N/A'
      url = get_type(type, identifier)
      extent_url = result.respond_to?(:extent_url) ? result.extent_url : 'N/A'

      {
        id: identifier,
        is_pa: result.is_a?(ProtectedArea),
        extent_url: extent_url,
        title: name,
        url: url
      }
    end
  end

  private

  def self.get_filters(type)
    case type
      when 'wdpa'
        { filters: { is_oecm: false } }
      when 'oecm'
        { filters: { is_oecm: true } }
      else
        {}
    end
  end

  def self.get_type(type, identifier)
    if type == 'country' || type == 'region'
      "/#{type}/#{identifier}"
    else
      "/#{identifier}"
    end
  end

  def self.identifier_field(type)
    IDENTIFIER_FIELDS[type] || :id
  end
end
