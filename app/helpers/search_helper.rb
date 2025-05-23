# frozen_string_literal: true

module SearchHelper
  include ApplicationHelper
  ALLOWED_PARAMS = Search::ALLOWED_FILTERS + %i[q main]

  def type_li_tag(type, current_type)
    selected_class = type == current_type ? 'selected' : ''
    content_tag(:li, class: selected_class) { yield }
  end

  def autocomplete_link(result)
    if result[:type] == 'protected_area'
      pa_autocomplete_link result
    else
      country_autocomplete_link result
    end
  end

  def facet_link(facet)
    search_params = params.permit(ALLOWED_PARAMS)
    link_params = search_params.merge({ facet[:query] => facet[:identifier] })

    link_to(url_for(link_params), class: 'filter-bar__value') do
      facet_count = content_tag(
        :strong,
        "(#{facet[:count]})",
        class: 'filter-bar__count'
      )

      raw "#{facet[:label]} #{facet_count}"
    end
  end

  def clear_filters_link(params)
    search_params = params.permit(ALLOWED_PARAMS)
    if search_params[:main] && search_params[:q].nil?
      return '' if search_params.to_h.length <= 2

      path = search_path(search_params.slice(:main, search_params[:main].to_sym))
      link_to 'Clear Filters', path, class: 'filter-bar__clear'
    else
      return '' if search_params.to_h.length <= 1

      path = search_path(search_params.slice(:q))
      link_to 'Clear Filters', path, class: 'filter-bar__clear'
    end
  end

  DEFAULT_TITLE = 'Protected Areas'
  def search_title(params, only_text = false)
    title = title_with_overseas_territories(params[:q]) || title_with_query(params[:q]) || title_with_filter(params) || DEFAULT_TITLE
    only_text ? strip_tags(title) : title
  end

  def cms_pages_for_search
    filter_options = { filters: { ancestor: @cms_page.id } }
    all_options = {
      page: 1,
      size: Search::CmsSerializer::DEFAULT_PAGE_SIZE[@cms_page.slug.underscore.to_sym],
      sort: { datetime: 'published_date' }
    }
   
    search_results = Search.search('', all_options.merge(filter_options), Search::CMS_INDEX)
    Search::CmsSerializer.new(search_results, all_options).serialize
  end

  private

  def title_with_query(query)
    if query.present?
      %(Search results for <strong class="u-link-color">"#{query}"</strong>).html_safe
    end
  end

  def title_with_overseas_territories(query)
    return nil unless query

    keywords = query.split(',')
    if keywords.select { |k| k .length == 3 }.count == keywords.count
      # They all belong to the same parent country already when coming from the marine page
      parent_country = Country.find_by_iso_3(keywords.first).try(:parent).try(:name)
      return nil unless parent_country

      %(Search results for <strong class="u-link-color">#{parent_country} overseas territories</strong>).html_safe
    end
  end

  TITLE_GENERATORS = {
    value: ->(config, param) { config['cases'][param.to_s] },
    model: lambda { |config, param|
      model = config['model'].constantize
      instance = model.find_by_id(param)
      config['template'] % instance.name
    }
  }.freeze

  def title_with_filter(params)
    main_filter       = params['main']
    green_list_filter = params['is_green_list']

    if green_list_filter == 'true' && main_filter.nil?
      return 'Protected Areas with Green List status'
    end

    return if main_filter.nil? || params[main_filter].nil?

    titles = Search.configuration['titles']
    config = titles[main_filter.to_s]
    type = config['type'].to_sym

    TITLE_GENERATORS[type][config, params[main_filter]]
  rescue StandardError => e
    Rails.logger.warn e
    nil
  end

  def pa_autocomplete_link(result)
    version = Rails.application.secrets.mapbox[:version]
    image_params = { id: result[:identifier], type: result[:type], version: version }

    link_to protected_area_url(result[:identifier]), class: 'autocompletion__result' do
      image = image_tag(
        'search-placeholder-country.png',
        alt: result[:name],
        data: { async: tiles_path(image_params) },
        class: 'autocompletion__image'
      )
      concat image
      concat(content_tag(:div, class: 'autocompletion__body') do
        concat content_tag(:span, result[:name])
        concat content_tag(:span, result[:type].titleize, class: 'autocompletion__type')
      end)
    end
  end

  def country_autocomplete_link(result)
    version = Rails.application.secrets.mapbox[:version]
    image_params = { id: result[:identifier], type: result[:type], version: version }
    type = (result[:type] == 'country' ? 'country/territory' : result[:type])

    link_to country_url(result[:identifier]), class: 'autocompletion__result' do
      image = image_tag(
        'search-placeholder-country.png',
        alt: result[:name],
        data: { async: tiles_path(image_params) },
        class: 'autocompletion__image'
      )
      concat image
      concat(content_tag(:div, class: 'autocompletion__body') do
        concat content_tag(:span, result[:name])
        concat content_tag(:span, type.titleize, class: 'autocompletion__type')
      end)
    end
  end

  def designation_link(desig)
    search_areas_path(filters: { designation: [desig] })
  end
end
