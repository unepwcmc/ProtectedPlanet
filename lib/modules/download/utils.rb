module Download
  module Utils
    def self.link_to download_name, type
      file_name = File.basename zip_path_for_type(download_name, type)
      S3.link_to file_name
    end

    def self.make_current
      S3.replace_all S3::IMPORT_PREFIX, S3::CURRENT_PREFIX
    end

    def self.zip_path_for_type download_name, type
      path = File.join(TMP_PATH, filename_for_type(download_name, type))
      "#{path}.zip"
    end

    def self.filename_for_type download_name, type
      "#{download_name}-#{type}"
    end

    def self.properties key
      JSON.parse($redis.get(key)) rescue {}
    end

    def self.key domain, identifier
      case domain
      when 'search'
        "downloads:searches:#{identifier}"
      when 'project'
        "downloads:projects:#{identifier}:all"
      when 'general'
        "downloads:general:#{identifier}"
      end
    end

    def self.filename domain, identifier
      "WDPA_#{Wdpa::S3.current_wdpa_identifier}".tap { |base_filename|
        base_filename << "_#{domain}"     if domain != 'general'
        base_filename << "_#{identifier}" if identifier != 'all'
      }
    end
  end
end
