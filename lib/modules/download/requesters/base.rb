require 'time'

class Download::Requesters::Base
  ENQUEUE_LOCK_TTL_SECONDS = 30 * 60 # prevent enqueue stampedes under concurrent requests

  def self.request *args
    instance = new(*args)
    instance.request
  end

  def request
    raise NotImplementedError, "Override this method to implement a requester"
  end

  def domain
    raise NotImplementedError, "Override this method to implement a requester"
  end

  protected

  def generation_info
    Download.generation_info(domain, identifier, format)
  end

  # Atomically ensure only one generation job is enqueued per download key.
  # This prevents a race where multiple web requests observe a non-generating status
  # and enqueue duplicate Sidekiq jobs before the worker has a chance to set status.
  #
  # Usage:
  #   enqueue_generation_once { DownloadWorkers::X.perform_async(...) }
  #
  def enqueue_generation_once
    status = generation_info['status']
    return false if %w[ready generating].include?(status)

    lock_key = Download::Utils.enqueue_lock_key(generation_key)
    acquired = $redis.set(lock_key, Time.now.to_i, nx: true, ex: ENQUEUE_LOCK_TTL_SECONDS)
    return false unless acquired

    begin
      jid = yield
      raise "Sidekiq enqueue returned nil jid" if jid.nil?

      mark_generating!(jid: jid, enqueued_at: Time.now.utc.iso8601)
      true
    rescue StandardError => e
      # If enqueue fails, allow future requests to try again quickly.
      $redis.del(lock_key)
      mark_failed!(e)
      Rails.logger.error("Download enqueue failed for #{generation_key}: #{e.message}")
      false
    end
  rescue StandardError => e
    Rails.logger.error("Download enqueue lock failed for #{generation_key}: #{e.message}")
    false
  end

  def json_response
    {
      'id' => computed_id,
      'title' => filename,
      'url' => url(filename),
      'hasFailed' => Download.has_failed?(domain, identifier, format),
      'token' => identifier
    }
  end

  def filename
    if ready?
      generation_info['filename']
    else
      if domain == 'search'
        # Use the 'backend token' / SHA256 digest instead of the normal token
        Download::Utils.filename(domain, token, format) 
      else
        Download::Utils.filename(domain, identifier, format)
      end
    end
  end

  def format
    @format
  end

  def computed_id
    "#{identifier}-#{format}"
  end

  def ready?
    generation_info['status'] == 'ready'
  end

  def url(filename)
    ready? ? Download.link_to(filename) : ''
  end

  def generation_key
    Download::Utils.key(domain, identifier, format)
  end

  def mark_generating!(jid: nil, enqueued_at: nil)
    properties = Download::Utils.properties(generation_key)
    generating_properties = properties.merge(
      'status' => 'generating',
      'generating_at' => Time.now.utc.iso8601
    )
    generating_properties['jid'] = jid if jid.present?
    generating_properties['enqueued_at'] = enqueued_at if enqueued_at.present?
    $redis.set(generation_key, generating_properties.to_json)
  end

  def mark_failed!(error)
    properties = Download::Utils.properties(generation_key)
    failed_properties = properties.merge(
      'status' => 'failed',
      'error' => error.message,
      'failed_at' => Time.now.utc.iso8601
    )
    $redis.set(generation_key, failed_properties.to_json)
  end
end
