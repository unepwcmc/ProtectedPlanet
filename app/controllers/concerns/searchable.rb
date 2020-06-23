module Concerns::Searchable
  extend ActiveSupport::Concern

  included do
    private

    def ignore_empty_query
      return render json: {} if search_params[:search_term].blank?
    end

    def load_search
      @query = search_params[:search_term]
      begin
        @search = Search.search(@query, search_options, search_index)
      rescue => e
        Rails.logger.warn("error in search controller: #{e.message}")
        @search = nil
      end
    end

    def search_options
      options = {filters: filters}
      options[:page] = params['requested_page'].to_i if params['requested_page'].present?
      options[:size] = params['items_per_page'].to_i if params['items_per_page'].present?
      options
    end

    def search_index
      _filters = search_params[:filters]
      _filters = _filters.is_a?(String) ? JSON.parse(_filters) : _filters
      is_area_category = _filters && _filters['ancestor'] == 'areas'
      (controller_name.include?('area') || is_area_category) ? Search::PA_INDEX : Search::DEFAULT_INDEX_NAME
    end

    DB_TYPES = %w(wdpa oecm all).freeze
    def check_db_type
      return unless params[:db_type]
      redirect_to :root unless DB_TYPES.include?(params[:db_type].downcase)
    end

    def load_search_from_query_string
      @query = search_params[:search_term]
      begin
        if search_params[:filters].present?
          @search = Search.search(@query, {}, search_index)
          load_filters
          @search = Search.search(@query, search_options, search_index)
        else
          @search = Search.search(@query, search_options, search_index)
        end
      rescue => e
        Rails.logger.warn("error in search controller: #{e.message}")
        @search = nil
      end
    end

    #
    # Retrieves the filters from params if present,
    # and sanitizes them from escaped string format
    #
    def filters
      return '' unless search_params[:filters].present?
      _filters = sanitise_filters
      _filters.to_hash.symbolize_keys.slice(*Search::ALLOWED_FILTERS)
    end

    def sanitise_filters
      _filters = search_params[:filters]
      _filters = _filters.is_a?(String) ? JSON.parse(_filters) : _filters

      _filters = sanitise_location_filter(_filters)
      _filters = sanitise_db_type_filter(_filters)
      _filters = sanitise_type_filter(_filters)
      _filters = sanitise_ancestor_filter(_filters)
      sanitise_special_status_filter(_filters)
    end

    #{'location' => {'type' => 'country', 'options' => ['Italy']}}
    def sanitise_location_filter(filters)
      if filters['location'].present? && filters['location']['options'].present?
        filters[filters['location']['type'].to_sym] = filters['location']['options']
      end

      filters
    end

    def sanitise_db_type_filter(filters)
      db_type = filters.delete('db_type')
      return filters if !db_type || db_type.length != 1

      filters[:is_oecm] = true if db_type.first == 'oecm'
      filters
    end

    def sanitise_type_filter(filters)
      # ['marine', 'terrestrial', 'all']
      is_type = filters.delete('is_type')
      return filters if !is_type || is_type.include?('all') || is_type.length != 1

      filters[:marine] = is_type.first == 'marine'
      filters
    end

    FAKE_CATEGORIES = %w(all areas).freeze
    def sanitise_ancestor_filter(filters)
      return filters unless filters['ancestor']

      if FAKE_CATEGORIES.include? filters['ancestor']
        filters.delete('ancestor')
      else
        filters['ancestor'] = filters['ancestor'].to_i
      end

      filters
    end

    def sanitise_special_status_filter(filters)
      # ['has_parcc_info', 'is_green_list']
      special_status = filters.delete('special_status')
      return filters unless special_status

      special_status.map do |status|
        filters[status.to_sym] = true
      end

      filters
    end

    def load_filters
      return if @filter_groups

      _filters = search_params[:filters]
      _filters = _filters.is_a?(String) ? JSON.parse(_filters) : _filters
      @db_type = (_filters.present? && _filters[:db_type].try(:first)) || 'all'
      @query ||= search_params[:search_term]
      @search_db_types = [
        {
          id: @db_type,
          title: I18n.t("global.area-types.#{@db_type}"),
          placeholder: I18n.t("global.placeholder.search-#{@db_type}")
        }
      ].to_json

      @filter_groups = @search ? Search::FiltersSerializer.new(@search).serialize : []
    end
  end
end
