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

    DB_TYPES = %w(wdpa oecm all).freeze
    def check_db_type
      redirect_to :root unless DB_TYPES.include?(params[:db_type].downcase)
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

      _filters = sanitise_location_filter(_filters)
      _filters = sanitise_db_type_filter(_filters)
      _filters = sanitise_type_filter(_filters)
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
      return filters if !db_type || db_type.length > 1

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
      @db_type = search_params[:db_type]
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
