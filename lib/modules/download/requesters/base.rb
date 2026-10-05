require 'time'
require 'sidekiq/api'

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

  # The current status of this download's Redis key, or nil when no key exists.
  # enqueue_generation_once depends on this: without it every request raised
  # NoMethodError into its own `rescue StandardError`, which logged and returned
  # false, so no job was ever pushed and the UI polled a download that had never
  # been enqueued.
  def status
    generation_info['status']
  end

  # Atomically ensure only one generation job is enqueued per download key.
  # This prevents a race where multiple web requests observe a non-generating status
  # and enqueue duplicate Sidekiq jobs before the worker has a chance to set status.
  #
  # Usage:
  #   enqueue_generation_once { DownloadWorkers::X.perform_async(...) }
  #
  def enqueue_generation_once
    lock_key = Download::Utils.enqueue_lock_key(generation_key)

    # Already generated: there is nothing to enqueue, and enqueueing anyway was
    # actively harmful. mark_generating! overwrites the 'ready' key, and
    # generation_info re-reads Redis on every call, so the json_response built
    # immediately afterwards saw 'generating' and returned url: ''. The caller
    # then had to wait for a completely redundant regeneration before /downloads/poll
    # handed back the URL the key already held.
    return false if status == 'ready'

    if status == 'generating'
      return false unless stale_generation?

      # The job backing this key is gone. Drop the enqueue lock too, otherwise
      # its 30-minute TTL would keep blocking the retry we just decided to allow.
      Rails.logger.warn("Download #{generation_key} was stuck in 'generating' with no live job; re-enqueueing")
      $redis.del(lock_key)
    end

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
  # Only Redis transport failures are swallowed here: a blip must not 500 the
  # download endpoint, and returning false lets the next poll try again.
  #
  # Anything else is a bug and must surface. This used to rescue StandardError,
  # and `status` was missing from every requester -- so each request raised
  # NoMethodError in here, logged one line, returned false and rendered HTTP 200
  # with an empty url. No job was ever pushed, nothing reached Appsignal, and the
  # UI polled a download that had never been enqueued.
  rescue Redis::BaseError, RedisClient::Error => e
    Rails.logger.error("Download enqueue lock failed for #{generation_key}: #{e.class}: #{e.message}")
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
    Download::Utils.write(generation_key, generating_properties)
  end

  def mark_failed!(error)
    properties = Download::Utils.properties(generation_key)
    failed_properties = properties.merge(
      'status' => 'failed',
      'error' => error.message,
      'failed_at' => Time.now.utc.iso8601
    )
    Download::Utils.write(generation_key, failed_properties)
  end

  # True when a key claims "generating" but nothing is actually working on it.
  #
  # This existed as a permanent dead end: co-located apps sharing Redis were
  # popping our jobs, failing to resolve the constant, and (retry: false)
  # dropping them. The key kept saying "generating" with no TTL, so every later
  # request short-circuited and the UI span forever.
  #
  # Age alone is not the test -- a full-WDPA export runs for hours and is
  # perfectly healthy. Past the grace period we ask Sidekiq whether the jid is
  # still alive, and only then declare it dead.
  def stale_generation?
    info = generation_info
    started_at = begin
      Time.parse(info['generating_at'].to_s)
    rescue ArgumentError, TypeError
      nil
    end

    # No timestamp means the key predates this code (or was hand-written); it
    # cannot be shown to be alive, so let it be retried.
    return true if started_at.nil?
    return false if Time.now.utc - started_at.utc < Download::Utils::GENERATING_GRACE

    !job_alive?(info['jid'])
  end

  def job_alive?(jid)
    return false if jid.blank?

    require 'sidekiq/api'
    return true if Sidekiq::Workers.new.any? { |_process, _thread, work| work.dig('payload', 'jid') == jid }

    Sidekiq::Queue.all.any? { |queue| queue.any? { |job| job.jid == jid } }
  rescue StandardError => e
    # If Sidekiq cannot be reached we must not conclude "dead" -- that would let
    # every polling request re-enqueue and stampede. Assume alive and let the
    # 24h GENERATING_TTL be the backstop.
    Rails.logger.warn("Could not determine liveness of download job #{jid}: #{e.message}")
    true
  end
end
