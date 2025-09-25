module Download
  def self.request(params)
    Download::Router.request(params.delete('domain'), params)
  end

  def self.poll(params)
    Download::Poller.poll(params)
  end

  def self.link_to(filename)
    Download::Utils.link_to filename
  end

  def self.set_email(params)
    Download::Router.set_email(params.delete('domain'), params)
  end

  def self.clear_downloads
    Utils.clear_downloads
  end

  def self.generation_info(domain, identifier, format)
    Download::Utils.properties(Download::Utils.key(domain, identifier, format))
  end

  def self.has_failed?(domain, identifier, format)
    status = generation_info(domain, identifier, format)['status']
    status.present? && !%w[generating ready].include?(status)
  end

  def self.is_ready?(domain, identifier, format)
    generation_info(domain, identifier, format)['status'] == 'ready'
  end

  TMP_PATH = File.join(Rails.root, 'tmp')
  CURRENT_PREFIX = 'current/'
  IMPORT_PREFIX = 'import/'

  GENERATORS = {
    shp: Download::Generators::Shapefile,
    csv: Download::Generators::Csv,
    gdb: Download::Generators::Gdb,
    pdf: Download::Generators::Pdf
  }.freeze

  def self.generate(format, download_name, opts = {})
    generator = GENERATORS[format.to_sym]
    zip_path = Utils.zip_path(download_name)

    generated = generator.generate zip_path, option(format, opts)

    return unless generated

    upload_to_s3 zip_path, opts[:for_import]
    clean_up zip_path
  end

  def self.option(format, opts)
    if format.to_s == 'pdf'
      opts[:identifier]
    else
      opts[:site_ids]
    end
  end

  def self.upload_to_s3(zip_path, for_import)
    download_name = File.basename(zip_path)
    prefix = for_import ? IMPORT_PREFIX : CURRENT_PREFIX
    prefixed_download_name = prefix + download_name

    S3.upload prefixed_download_name, zip_path
  end

  def self.clean_up(path)
    FileUtils.rm_rf path
  end
end
