module HomeHelper
  def nav_main_background_class controller_name
    if controller_name.downcase == 'home'
      'home-nav-main'
    end
  end

  def map_filtered?
    params.include?('marine') || params.include?('iucn_category')
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
end
