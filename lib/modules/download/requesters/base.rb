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

  # Atomically ensure only one generation job is enqueued per download key.
  # This prevents a race where multiple web requests observe a non-generating status
  # and enqueue duplicate Sidekiq jobs before the worker has a chance to set status.
  #
  # Usage:
  #   enqueue_generation_once { DownloadWorkers::X.perform_async(...) }
  #
  def enqueue_generation_once
    info = generation_info
    status = info['status']
    return false if status == 'ready'
    return false if status == 'generating' && generation_in_flight?(info)

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

  # A 'generating' status is only worth trusting while the job behind it still
  # exists. These workers run with retry: false, so a worker killed mid-render
  # (container restart, OOM) leaves the status at 'generating' with nobody left to
  # move it on - and since we refuse to enqueue while it says 'generating', that
  # download could never be requested again without someone deleting the Redis key
  # by hand.
  #
  # Two things keep a live job from being duplicated: the enqueue lock, which
  # exists from the moment we push until the worker's ensure block clears it (so it
  # covers the queued-but-not-started window a hard-killed worker leaves behind
  # too), and the Sidekiq work set, which lists jobs actually running right now and
  # is backed by a process heartbeat - so a job that outlives the lock's TTL still
  # reads as in-flight, while one whose process died drops out of it.
  def generation_in_flight?(info)
    return true if $redis.exists?(Download::Utils.enqueue_lock_key(generation_key))

    jid = info['jid']
    # Records written before jids were tracked tell us nothing; keep the old,
    # conservative behaviour rather than risk enqueueing a duplicate.
    return true if jid.blank?

    Sidekiq::Workers.new.any? { |_process, _thread, work| work.job.jid == jid }
  rescue StandardError => e
    Rails.logger.warn("Could not verify in-flight download #{generation_key}: #{e.message}")
    true
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
