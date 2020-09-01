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
        _index = search_index
        @search = Search.search(@query, search_options, _index)
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
      options.merge(@sorter || {})
    end

    INDEX_BY_TYPE = {
      'site' => Search::PA_INDEX,
      'country' => Search::COUNTRY_INDEX,
      'region' => Search::REGION_INDEX,
      'all' => Search::DEFAULT_INDEX_NAME,
      'areas' => Search::PA_INDEX,
      'cms' => Search::CMS_INDEX
    }.freeze
    def search_index
      _index = search_params[:search_index]
      return INDEX_BY_TYPE[_index] if _index.present?

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
      Search::FilterParams.standardise(parsed_filters)
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
