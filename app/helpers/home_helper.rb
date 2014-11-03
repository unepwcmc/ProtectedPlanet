module HomeHelper
  def nav_main_background_class controller_name
    if controller_name.downcase == 'home'
      'home-nav-main'
    end
  end

  def filter_url_attribute
    if map_filtered?
      "data-url=\"#{api_search_points_url(params)}\"".html_safe
    end
  end

  def iucn_data_attribute
    if params[:iucn_category].present?
      "data-iucn-category=\'#{selected_iucn_categories.to_json}\'".html_safe
    end
  end

  def marine_attribute
    if params[:marine].present?
      "data-marine=\"#{selected_marine_filter}\"".html_safe
    end
  end

  def link_to_filter link_name, key, value, options = {}
    link_params = params.merge({key => value})
    link_to link_name, root_path(link_params), options
  end

  def filter_link_active_class key, value
    if params.include?(key) && (params[key] == value || params[key].include?(value))
      "active-filter"
    else
      ""
    end
  end

  private

  def selected_iucn_categories
    IucnCategory.where('id IN (?)', params[:iucn_category]).pluck(:name)
  end

  def selected_marine_filter
    params[:marine] ? 1 : 0
  end

  def map_filtered?
    params.include?('marine') || params.include?('iucn_category')
  end
end
