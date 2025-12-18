class DownloadWorkers::Base
  include Sidekiq::Worker
  sidekiq_options retry: false, backtrace: true

  def self.perform_async *args
    queue = if args.last.is_a?(Hash) && args.last[:for_import]
              args.pop unless keep_last_arg args
              'import'
            else
              'default'
            end

    jid = Sidekiq::Client.push('class' => self, 'queue' => queue, 'args' => args)
    jid
  end

  protected

  def key(identifier, format)
    Download::Utils.key domain, identifier, format
  end

  def filename(identifier, format)
    Download::Utils.filename domain, identifier, format
  end

  def while_generating(key)
    properties = Download::Utils.properties(key)
    generating_properties = properties.merge({ 'status' => 'generating' })
    $redis.set(key, generating_properties.to_json)

    begin
      result_json = yield
      $redis.set(key, result_json)
    rescue StandardError => e
      failed_properties = properties.merge({ 'status' => 'failed', 'error' => e.message })
      $redis.set(key, failed_properties.to_json)
      Rails.logger.error("Download generation failed for #{key}: #{e.message}")
      # Do not re-raise so status remains failed and future requests can re-enqueue
      failed_properties.to_json
    ensure
      # Clear the enqueue lock (if any) so failed downloads can be retried immediately.
      # This is safe because requesters also check the main key's status (`generating`/`ready`)
      # to prevent duplicate enqueueing.
      $redis.del(Download::Utils.enqueue_lock_key(key))
    end
  end

  def self.keep_last_arg(args)
    instance_method(:perform).arity.abs == args.size
  end
end
