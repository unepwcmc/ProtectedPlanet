class S3
  CURRENT_PREFIX = 'current/'
  IMPORT_PREFIX = 'import/'

  def initialize
    base = {
      access_key_id: Rails.application.secrets.aws_access_key_id,
      secret_access_key: Rails.application.secrets.aws_secret_access_key,
      region: Rails.application.secrets.s3_region
    }
    # Local/dev: point at an S3-compatible endpoint (e.g. MinIO) when set. Path
    # style is required because per-bucket virtual hosts don't resolve locally.
    # Unset in production, so real AWS is used unchanged.
    if (endpoint = ENV['AWS_S3_ENDPOINT']).present?
      base = base.merge(endpoint: endpoint, force_path_style: true)
    end

    @s3 = Aws::S3::Resource.new(base)
    @client = Aws::S3::Client.new(base)
  end

  def self.upload(object_name, file_path, opts={})
    s3 = S3.new
    s3.upload object_name, file_path, opts
  end

  def self.delete_all(path)
    s3 = S3.new
    s3.delete_all(path)
  end

  def self.link_to(file_name, opts={for_import: false})
    prefix = opts[:for_import] ? IMPORT_PREFIX : CURRENT_PREFIX
    prefixed_file_name = prefix + file_name

    url = Rails.application.secrets.aws_s3_url
    URI.join(url, prefixed_file_name).to_s
  end

  def upload(object_name, source, opts)
    # Default to downloads bucket unless specified (e.g. for when uploading CMS files)
    bucket = opts[:bucket] || Rails.application.secrets.aws_downloads_bucket

    object = @s3.bucket(bucket).object(object_name)
    object.upload_file(source)

    # Public-read so download links resolve. Skipped against a local S3-compatible
    # endpoint (MinIO), which doesn't implement per-object ACLs. Real AWS unchanged.
    unless ENV['AWS_S3_ENDPOINT'].present?
      @client.put_object_acl({
        acl: "public-read",
        bucket: bucket,
        key: object_name,
      })
    end
    true
  end


  def delete_all(path)
    bucket = @s3.bucket(Rails.application.secrets.aws_downloads_bucket)
    objects = bucket.objects(prefix: path)

    objects.each do |objs|
      objs.object.delete
    end
  end
end
