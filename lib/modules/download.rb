module Download
  def self.request params
    Download::Router.request(params.delete('domain'), params)
  end

  def self.poll params
    Download::Router.poll(params.delete('domain'), params)
  end

  def self.link_to filename, type
    Download::Utils.link_to filename, type
  end

  def self.set_email
    Download::Router.set_email(params.delete('domain'), params)
  end

  def self.make_current
    Utils.make_current
  end


  TMP_PATH = File.join(Rails.root, 'tmp')
  CURRENT_PREFIX = 'current/'
  IMPORT_PREFIX = 'import/'

  GENERATORS = [
    Download::Generators::Csv,
    Download::Generators::Shapefile,
    Download::Generators::Kml
  ]

  def self.generate download_name, opts={}
    GENERATORS.each do |generator|
      zip_path = Utils.zip_path_for_type(download_name, generator::TYPE)

      generated = generator.generate zip_path, opts[:wdpa_ids]

      if generated
        upload_to_s3 zip_path, opts[:for_import]
        clean_up zip_path
      end
    end
  end

  private

  def self.upload_to_s3 zip_path, for_import
    download_name = File.basename(zip_path)
    prefix = for_import ? IMPORT_PREFIX : CURRENT_PREFIX
    prefixed_download_name = prefix + download_name

    S3.upload prefixed_download_name, zip_path
  end

  def self.clean_up path
    FileUtils.rm_rf path
  end
end
