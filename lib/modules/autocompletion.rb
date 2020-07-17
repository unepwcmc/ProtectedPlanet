module Autocompletion
  AUTOCOMPLETION_KEY = "autocompletion".freeze
  IDENTIFIER_FIELDS = {
    'protected_area' => :wdpa_id,
    'country' => :iso_3
  }.freeze

  def self.lookup(term, db_type='wdpa', search_index=Search::PA_INDEX)
    filters = { filters: { is_oecm: db_type == 'oecm' } }
    search = Search.search(term.downcase, filters, search_index)

    results = search.results.objects.values.compact.flatten

    results.map do |result|
      name = result.name
      type = result.class.name.underscore
      identifier = result.send(identifier_field(type))

      geom_type = result.is_a?(ProtectedArea) ? result.the_geom.geometry_type.to_s : 'N/A'
      url = type == 'country' ? "/country/#{identifier}" : "/#{identifier}"

      {
        id: identifier,
        geom_type: geom_type,
        title: name,
        url: url,
      }
    end
  end

  private

  def self.identifier_field(type)
    IDENTIFIER_FIELDS[type] || :id
  end
end
