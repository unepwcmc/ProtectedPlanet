module Download
  module Utils
    def self.link_to(download_name)
      file_name = File.basename zip_path(download_name)
      S3.link_to file_name
    end

    def self.download_columns(opts = {})
      opts = { reject: [] }.merge(opts)
      add_quotes = ->(str) { %("#{str}") }

      Download::Config.polygons_columns
        .reject { |col| opts[:reject].include? col }
        .map(&:upcase)
        .map(&add_quotes)
        .join(',')
    end

    def self.source_columns
      add_quotes = ->(str) { %("#{str}") }

      Download::Config.source_columns
        .map(&:upcase)
        .map(&add_quotes)
        .join(',')
    end

    def self.clear_downloads
      S3.delete_all S3::CURRENT_PREFIX
      $redis.keys('downloads:*').each { |d| $redis.del d }
      Download::Generators::Base.clean_tmp_download_views
      Download::Generators::Base.clean_up_generated_source
    end

    def self.zip_path(download_name)
      path = File.join(TMP_PATH, download_name)
      "#{path}.zip"
    end

    def self.properties(key)
      JSON.parse($redis.get(key))
    rescue StandardError
      {}
    end

    def self.key(domain, identifier, format)
      case domain
      when 'search'
        "downloads:searches:#{format}:#{identifier}"
      when 'project'
        "downloads:projects:#{format}:#{identifier}:all"
      when 'general'
        "downloads:general:#{format}:#{identifier}"
      when 'protected_area'
        "downloads:protected_area:#{format}:#{identifier}"
      when 'pdf'
        "downloads:pdf:#{format}:#{identifier}"
      end
    end

    BASENAMES = {
      'wdpa' => 'WDPA',
      'oecm' => 'WDOECM',
      'default' => 'WDPA_WDOECM'
    }.freeze
    # identifier is the search token if domain is search
    def self.filename(domain, identifier, format)
      basename = BASENAMES[identifier] || BASENAMES['default']
      current_release_label = Download::Config.current_label
      "#{basename}_#{current_release_label}_Public".tap do |base_filename|
        base_filename << "_#{identifier}" if needs_identifier_suffix?(domain, identifier)
        base_filename << "_#{format}" if format.present? && format != 'gdb'
      end
    end

    def self.extract_filters(filters)
      filters = Search::FilterParams.standardise(filters)
      filters.stringify_keys.slice(*::Search::ALLOWED_FILTERS.map(&:to_s))
    end

    def self.filters_dump(filters)
      Marshal.dump filters.to_hash.sort.to_json
    end

    def self.search_token(term, filters)
      return 'all' if term.empty? && filters.empty?

      Digest::SHA256.hexdigest(term.to_s + filters_dump(filters))
    end

    def self.needs_identifier_suffix?(domain, identifier)
      return true if %w[search protected_area pdf].include?(domain)

      !BASENAMES.keys.include?(identifier)
    end
  end
end
