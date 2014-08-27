class S3
  def initialize
    @s3 = AWS::S3.new({
      access_key_id: Rails.application.secrets.aws_access_key_id,
      secret_access_key: Rails.application.secrets.aws_secret_access_key
    })
  end

  def self.upload object_name, file_path
    s3 = S3.new
    s3.upload object_name, file_path
  end

  def self.replace_all from, to
    s3 = S3.new
    s3.replace_all from, to
  end

  def upload object_name, file_path
    bucket = @s3.buckets[Rails.application.secrets.aws_downloads_bucket]
    object = bucket.objects[object_name]

    file_path = Pathname.new(file_path)
    file_size = File.size(file_path)

    object.write(file_path, content_length: file_size)
  end

  def replace_all from, to
    bucket = @s3.buckets[Rails.application.secrets.aws_downloads_bucket]
    replacing_objects = bucket.objects.with_prefix(from)
    replaced_objects = bucket.objects.with_prefix(to)

    bucket.objects.delete(replaced_objects)

    replacing_objects.each do |object|
      new_key = object.key.gsub(from, to)
      object.move_to(new_key)
    end
  end
end
