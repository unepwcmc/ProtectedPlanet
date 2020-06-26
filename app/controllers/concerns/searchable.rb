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

    DEFAULT_PAGE = 1.freeze
    DEFAULT_SIZE = 9.freeze
    def search_options
      options = {filters: filters}
      requested_page = search_params[:requested_page].try(:to_i) || DEFAULT_PAGE
      items_per_page = search_params[:items_per_page].try(:to_i) || DEFAULT_SIZE
      options[:page] = requested_page
      options[:size] = items_per_page
      options
    end

    INDEX_BY_TYPE = {
      'site' => Search::PA_INDEX,
      'country' => Search::COUNTRY_INDEX,
      'region' => Search::REGION_INDEX,
      'all' => Search::DEFAULT_INDEX_NAME,
      'areas' => Search::PA_INDEX
    }.freeze
    def search_index
      _index = INDEX_BY_TYPE[parsed_filters['ancestor']] if parsed_filters
      return _index if _index

      INDEX_BY_TYPE[search_params[:geo_type]] || Search::DEFAULT_INDEX_NAME
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
      return '' if %w(country region).include?(search_params[:geo_type])
      _filters = sanitise_filters
      _filters.to_hash.symbolize_keys.slice(*Search::ALLOWED_FILTERS)
    end

    def sanitise_filters
      _filters = sanitise_location_filter(parsed_filters)
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
      db_type = db_type && db_type.reject { |i| i == 'all' }
      return filters if db_type.blank? || db_type.length != 1

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
      ancestor = filters.delete('ancestor')

      return filters if ancestor.blank? || FAKE_CATEGORIES.include?(ancestor)

      filters['ancestor'] = ancestor.to_i

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

      @db_type = parsed_filters.present? && parsed_filters[:db_type].try(:first)
      _db_type_id = @db_type || 'all'
      @query ||= search_params[:search_term]
      @search_db_types = [
        {
          id: _db_type_id,
          title: I18n.t("global.area-types.#{_db_type_id}"),
          placeholder: I18n.t("global.placeholder.search-#{_db_type_id}")
        }
      ].to_json

      @filter_groups = @search ? Search::FiltersSerializer.new(@search).serialize : []
    end

    def parsed_filters
      return @parsed_filters if @parsed_filters

      _filters = search_params[:filters]
      @parsed_filters = _filters.is_a?(String) ? JSON.parse(_filters) : _filters
    end
  end
end
