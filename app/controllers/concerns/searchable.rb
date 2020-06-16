module Concerns::Searchable
  extend ActiveSupport::Concern

  included do
    private

    def load_search
      @query = search_params[:search_term]
      begin
        @search = Search.search(@query, search_options, search_index)
      rescue => e
        Rails.logger.warn("error in search controller: #{e.message}")
        @search = nil
      end

      @main_filter = params[:main]
    end

    def search_options
      options = {filters: filters}
      options[:page] = params['requested_page'].to_i if params['requested_page'].present?
      options[:size] = params['items_per_page'].to_i if params['items_per_page'].present?
      options
    end

    def search_index
      controller_name.include?('area') ? Search::AREAS_INDEX_NAME : Search::DEFAULT_INDEX_NAME
    end

    AREA_TYPES = %w(wdpa oecm).freeze
    def check_area_type
      redirect_to :root unless AREA_TYPES.include?(params[:area_type].downcase)
    end

    #
    # Retrieves the filters from params if present,
    # and sanitizes them from escaped string format
    #
    def filters
      return '' unless params['filters'].present?
      _filters = sanitise_filters
      _filters.symbolize_keys.slice(*Search::ALLOWED_FILTERS)
    end

    def sanitise_filters
      _filters = JSON.parse(params['filters'])
      #{'location' => {'type' => 'country', 'id' => 'Italy'}}
      if _filters['location'].present? && _filters['location']['id'].present?
        _filters[_filters['location']['type'].to_sym] = _filters['location']['id']
      end

      _filters = sanitise_db_type_filter(_filters)
      _filters = sanitise_type_filter(_filters)
      sanitise_special_status_filter(_filters)
    end

    def sanitise_db_type_filter(_filters)
      db_type = _filters.delete('db_type')
      return _filters if !db_type || db_type.length > 1

      _filters[:is_oecm] = true if db_type.first == 'oecm'
      _filters
    end

    def sanitise_type_filter(_filters)
      # ['marine', 'terrestrial', 'all']
      is_type = _filters.delete('is_type')
      return _filters if !is_type || is_type.include?('all') || is_type.length != 1

      _filters[:marine] = is_type.first == 'marine'
      _filters
    end

    def sanitise_special_status_filter(_filters)
      # ['has_parcc_info', 'is_green_list']
      special_status = _filters.delete('special_status')
      return _filters unless special_status

      special_status.map do |status|
        _filters[status.to_sym] = true
      end

      _filters
    end

    def load_filters
      @area_type = search_params[:area_type]
      @query ||= search_params[:search_term]
      @search_area_types = [
        {
          id: @area_type,
          title: I18n.t("global.area-types.#{@area_type}"),
          placeholder: I18n.t("global.placeholder.search-#{@area_type}")
        }
      ].to_json

      @filter_groups = @search ? Search::FiltersSerializer.new(@search).serialize : []
    end
  end
end
