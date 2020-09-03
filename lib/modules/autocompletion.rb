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

    # Count the number of items with the same name
    # and store it in an hash
    names_counts = {}
    results.map do |r|
      names_counts[r.name] ||= 0
      names_counts[r.name] += 1
    end

    results.map do |result|
      name = computed_name(result, names_counts)
      type = result.class.name.underscore
      identifier = result.send(identifier_field(type))

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

  # If more than one item with the same name has been counted
  # and it's a PA, add the designation name in brackets
  def self.computed_name(item, names_counts)
    return item.name unless item.is_a?(ProtectedArea)

    if names_counts[item.name] > 1
      "#{item.name} (#{item.designation.name})"
    else
      item.name
    end
  end
end
