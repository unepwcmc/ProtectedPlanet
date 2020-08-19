class DownloadWorkers::Base
  include Sidekiq::Worker
  sidekiq_options :retry => false, :backtrace => true

  def self.perform_async *args
    queue = if args.last.is_a?(Hash) && args.last[:for_import]
      args.pop unless keep_last_arg args
      'import'
    else
      'default'
    end

    Sidekiq::Client.push('class' => self, 'queue' => queue, 'args' => args)
  end

  protected

  def key identifier, format
    Download::Utils.key domain, identifier, format
  end

  def filename identifier, format
    Download::Utils.filename domain, identifier, format
  end

  def while_generating key
    properties = Download::Utils.properties(key)
    generating_properties = properties.merge({'status' => 'generating'})

    $redis.set(key, generating_properties.to_json)
    $redis.set(key, yield)
  end

  def links
    ['csv', 'shp', 'gdb', 'pdf'].each_with_object({}) do |type, hash|
      hash[type] = Download.link_to filename, type
    end.to_json
  end

  def self.keep_last_arg args
    self.instance_method(:perform).arity.abs == args.size
  end
end
