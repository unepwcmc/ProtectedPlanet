class S3
  CURRENT_PREFIX = 'current/'
  IMPORT_PREFIX = 'import/'

  def initialize
    @s3 = Aws::S3::Resource.new({
      access_key_id: Rails.application.secrets.aws_access_key_id,
      secret_access_key: Rails.application.secrets.aws_secret_access_key,
      region: Rails.application.secrets.s3_region
                                })
    @client = Aws::S3::Client.new(region: Rails.application.secrets.s3_region)
  end

  def self.upload object_name, file_path, opts={}
    s3 = S3.new
    s3.upload object_name, file_path, opts
  end

  def self.delete_all path
    s3 = S3.new
    s3.delete_all path
  end

  def self.link_to file_name, opts={for_import: false}
    prefix = opts[:for_import] ? IMPORT_PREFIX : CURRENT_PREFIX
    prefixed_file_name = prefix + file_name

    url = Rails.application.secrets.aws_s3_url
    URI.join(url, prefixed_file_name).to_s
  end

  def upload object_name, source, opts
    bucket = @s3.bucket(Rails.application.secrets.aws_downloads_bucket)
    object = bucket.object(object_name)
    object.upload_file(source)
    @client.put_object_acl({
                        acl: "public-read",
                        bucket: Rails.application.secrets.aws_downloads_bucket,
                        key: object_name,
                           })

    object.get(response_target: "#{source}.dl")
    return

    if opts[:raw]
      object.write(data: source, acl: :public_read)
    else
      file_path = Pathname.new(source)
      file_size = File.size(file_path)

      object.write(file_path, acl: :public_read, content_length: file_size)
    end
  end


  def delete_all path
    bucket = @s3.bucket(Rails.application.secrets.aws_downloads_bucket)
    objects = bucket.objects.with_prefix(path)

    objects.delete_all
  end
end
