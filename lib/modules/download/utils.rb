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
      Download::Config.source_columns.map do |column|
        %(#{column} AS "#{column.upcase}")
      end.join(',')
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
      parsed = JSON.parse($redis.get(key))
      # JSON.parse("null") returns nil rather than raising, and every caller
      # treats this as a Hash (properties['status'], properties.merge).
      parsed.is_a?(Hash) ? parsed : {}
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

    ENQUEUE_LOCK_SUFFIX = 'enqueue_lock'.freeze
    def self.enqueue_lock_key(generation_key)
      "#{generation_key}:#{ENQUEUE_LOCK_SUFFIX}"
    end

    # Redis on the shared host runs with `--maxmemory 2gb --maxmemory-policy
    # noeviction`, so a key that never expires is not merely untidy: once the
    # ceiling is reached Redis refuses writes for every app on the box. These
    # keys were previously written with no TTL at all (`ttl=-1`), so the
    # downloads keyspace only ever grew. Everything gets an expiry now.
    READY_TTL      = 30.days
    GENERATING_TTL = 24.hours
    FAILED_TTL     = 1.hour

    # A download that has claimed "generating" for longer than this, with no live
    # Sidekiq worker holding its jid, is treated as dead and may be re-enqueued.
    # Deliberately generous: a full-WDPA .gdb export legitimately runs a long
    # time. Age alone never decides -- liveness does. See
    # Download::Requesters::Base#stale_generation?
    GENERATING_GRACE = 15.minutes

    def self.ttl_for(status)
      case status
      when 'ready'      then READY_TTL
      when 'generating' then GENERATING_TTL
      else                   FAILED_TTL
      end
    end

    # Single write path for download status keys, so no caller can reintroduce a
    # TTL-less key. Accepts either a Hash or an already-encoded JSON String,
    # because the workers hand back whatever the generator returned.
    def self.write(key, payload)
      hash = payload.is_a?(Hash) ? payload : (JSON.parse(payload.to_s) rescue nil)
      body = payload.is_a?(Hash) ? payload.to_json : payload.to_s

      $redis.set(key, body, ex: ttl_for(hash.is_a?(Hash) ? hash['status'] : nil).to_i)
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
