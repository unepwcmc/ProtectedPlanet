module SearchAreaLinkFilters
  SPECIAL_STATUS_FILTER_KEY = :special_status

  def self.db_types_filters(wdpa_plus_ocem: true)
    { db_type: wdpa_plus_ocem ? %w[wdpa oecm] : %w[wdpa] }
  end

  def self.wdpa_and_marine_is_true_filters
    db_types_filters(wdpa_plus_ocem: false).merge(is_marine: true)
  end

  def self.green_list_status_filters
    { SPECIAL_STATUS_FILTER_KEY => %w[is_green_list is_green_list_candidate] }
  end

  def self.green_list_filters
    db_types_filters(wdpa_plus_ocem: true).merge(green_list_status_filters)
  end

  def self.is_type_marine_filters
    { is_type: %w[marine] }
  end

  def self.special_status_is_transboundary_filters
    { SPECIAL_STATUS_FILTER_KEY => %w[is_transboundary] }
  end

  def self.designation_filters(designation)
    { designation: [designation] }
  end

  def self.home_category_filters(filter)
    if filter == 'is_green_list'
      { SPECIAL_STATUS_FILTER_KEY => [filter] }
    else
      { is_type: [filter] }
    end
  end
end
