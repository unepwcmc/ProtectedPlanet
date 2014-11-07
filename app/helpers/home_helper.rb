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
    link_to link_name, root_path(link_params(key, value)), options
  end

  def filter_link_active_class key, value
    in_params?(key, value) ? "active-filter" : ""
  end

  def size_class
    map_filtered? ? "sub-nav-open" : ""
  end

  def map_filtered?
    params.include?('marine') || params.include?('iucn_category')
  end

  private

  def link_params key, value
    value = value.to_s
    params_copy = params.dup

    if /(.+)\[\]/ =~ key
      arr = params_copy[$1] ||= []
      arr.include?(value) ? arr.delete(value) : arr.push(value)

      params_copy.delete($1) if arr.empty?
    else
      params_copy[key] == value ? params_copy.delete(key) : params_copy[key] = value
    end

    params_copy
  end

  def in_params? key, value
    params[key] == value || params[key].try(:include?, value)
  end

  def selected_iucn_categories
    IucnCategory.where('id IN (?)', params[:iucn_category]).pluck(:name)
  end

  def selected_marine_filter
    params[:marine] ? 1 : 0
  end
end
