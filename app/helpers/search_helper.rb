module SearchHelper
  include ApplicationHelper

  def type_li_tag type, current_type
    selected_class = (type == current_type) ? "selected" : ""
    content_tag(:li, class: selected_class) { yield }
  end

  def autocomplete_link result
    if result[:type] == 'protected_area'
      pa_autocomplete_link result
    else
      country_autocomplete_link result
    end
  end

  def facet_link facet
    link_params = params.merge({facet[:query] => facet[:identifier]})

    link_to url_for(link_params) do
      facet_count = content_tag(:strong, "(#{facet[:count]})", class: "filter-bar__value")
      raw "#{facet[:label]} #{facet_count}"
    end
  end

  def clear_filters_link params
    if params[:main] && params[:q].nil?
      return '' if params.length <= 4

      path = search_path(params.slice(:main, params[:main].to_sym))
      link_to "Clear Filters", path, class: "filter-bar__reset"
    else
      return '' if params.length <= 3

      path = search_path(params.slice(:q))
      link_to "Clear Filters", path, class: "filter-bar__reset"
    end
  end

  DEFAULT_TITLE = 'Protected Areas'
  def search_title params, only_text=false
    title = title_with_query(params[:q]) or title_with_filter(params) or DEFAULT_TITLE
    only_text ? strip_tags(title) : title
  end

  private

  def title_with_query query
    if query.present?
      %{Search results for <strong>"#{query}"</strong>}.html_safe
    end
  end

  TITLE_GENERATORS = {
    value: -> config, param { config['cases'][param.to_s] },
    model: -> config, param {
      model = config['model'].constantize
      instance = model.find_by_id(param)
      config['template'] % instance.name
    }
  }
  def title_with_filter params
    main_filter = params['main']
    return if main_filter.nil? || params[main_filter].nil?

    titles = Search.configuration['titles']
    config = titles[main_filter.to_s]
    type = config['type'].to_sym

    return TITLE_GENERATORS[type][config, params[main_filter]]
  rescue => err
    Rails.logger.warn err
    nil
  end

  def pa_autocomplete_link result
    version = Rails.application.secrets.mapbox['version']
    image_params = {id: result[:identifier], version: version}

    link_to protected_area_url(result[:identifier]) do
      image = image_tag(
        "search-placeholder-country.png",
        "alt" => result[:name],
        "data-async" => tiles_path(image_params),
      )
      raw "#{image}#{result[:name]}"
    end
  end

  def country_autocomplete_link result
    link_to country_url(result[:identifier]) do
      image = image_tag("search-placeholder-country.png")
      raw "#{image}#{result[:name]}"
    end
  end
end
