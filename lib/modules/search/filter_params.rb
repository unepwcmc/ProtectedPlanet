class Search::FilterParams

  def self.standardise(filters)
    self.new(filters).standardise
  end

  def initialize(filters)
    @filters = filters
  end

  def standardise
    return {} if filters.blank?

    sanitise_location_filter
    sanitise_db_type_filter
    sanitise_type_filter
    sanitise_ancestor_filter
    sanitise_categories_filter
    filters
  end

  #{'location' => {'type' => 'country', 'options' => ['Italy']}}
  def sanitise_location_filter
    if filters['location'].present? && filters['location']['options'].present?
      filters[filters['location']['type'].to_sym] = filters['location']['options']
    end

    # ensure to delete 'location' as it conflicts with the coordinates location filter in the Search modules
    filters.delete('location')
  end

  def sanitise_db_type_filter
    db_type = filters.delete('db_type')
    db_type = db_type && db_type.reject { |i| i == 'all' }
    return if db_type.blank? || db_type.length != 1

    filters[:is_oecm] = true if db_type.first == 'oecm'
  end

  def sanitise_type_filter
    # ['marine', 'terrestrial', 'all']
    is_type = filters.delete('is_type')
    return if !is_type || is_type.include?('all') || is_type.length != 1

    filters[:marine] = is_type.first == 'marine'
  end

  FAKE_CATEGORIES = %w(all areas).freeze
  def sanitise_ancestor_filter
    ancestor = filters.delete('ancestor')

    return if ancestor.blank? || FAKE_CATEGORIES.include?(ancestor)

    filters['ancestor'] = ancestor.to_i
  end

  def sanitise_categories_filter
    topics = filters.delete('topics')
    types = filters.delete('types')

    return if topics.blank? && types.blank?

    filters[:topic] = topics if topics.present?
    filters[:page_type] = types if types.present?
  end

  private

  def filters
    @filters
  end
end