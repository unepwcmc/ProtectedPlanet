module Download
  module Utils
    def self.link_to download_name
      file_name = File.basename zip_path(download_name)
      S3.link_to file_name
    end

    def self.download_columns opts={}
      opts = {reject: []}.merge(opts)
      add_quotes = -> str { %{"#{str}"} }

      Download::Queries::POLYGONS_COLUMNS
        .reject { |col| opts[:reject].include? col }
        .map(&:upcase)
        .map(&add_quotes)
        .join(",")
    end

    def self.source_columns
      add_quotes = -> str { %{"#{str}"} }

      Download::Queries::SOURCE_COLUMNS
        .map(&:upcase)
        .map(&add_quotes)
        .join(",")
    end

    def self.clear_downloads
      S3.delete_all S3::CURRENT_PREFIX
      $redis.keys("downloads:*").each { |d| $redis.del d }
    end

    def self.zip_path download_name
      path = File.join(TMP_PATH, download_name)
      "#{path}.zip"
    end

    def self.properties key
      JSON.parse($redis.get(key)) rescue {}
    end

    def self.key domain, identifier, format
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

    def self.filename domain, identifier, format
      "WDPA_#{Wdpa::S3.current_wdpa_identifier}".tap { |base_filename|
        base_filename << "_#{domain}"     if domain != 'general'
        base_filename << "_#{identifier}_#{format}" if (identifier != 'all' && identifier.present?)
      }
    end
  end
end
