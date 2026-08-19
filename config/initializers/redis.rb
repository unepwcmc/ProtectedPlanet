require 'uri'

# Every Kamal app co-located on the staging host is handed the SAME redis URL,
# pointing at logical database 0:
#
#   protectedplanet                 REDIS_URL          .../0   queues default, import
#   wdpa-pp-data-management-portal  SIDEKIQ_REDIS_URL  .../0   queues upload, default
#   api-pp-authentication           SIDEKIQ_REDIS_URL  .../0   queue  default
#
# Sidekiq 7 removed namespace support, so `queue:default` is one physical Redis
# list shared by three different Rails apps. Whichever process pops a job first
# wins; the other two cannot resolve the job's constant and raise NameError.
# DownloadWorkers::Base sets `retry: false`, so a stolen download job was
# discarded without a trace and its status key stayed at "generating" forever,
# which then blocked every future request for that download (see
# Download::Requesters::Base#enqueue_generation_once).
#
# Pinning this app to its own logical database makes both the keyspace and the
# queues ours alone. REDIS_DB overrides it for environments where the injected
# URL is already app-specific -- production runs its own Redis, so set
# REDIS_DB=0 there to keep using the database its existing keys live in.
#
# NB: the enqueue side and the run side must agree. config/initializers/sidekiq.rb
# configures BOTH the Sidekiq client and server from this same URL; if only one
# side moved, Puma would enqueue into one database and Sidekiq would poll another.
module PPRedis
  DEFAULT_DB = 3

  # NB: this must not raise when REDIS_URL is missing.
  #
  # assets:precompile and vite:build_all boot the whole Rails application inside
  # the image build, where no runtime secrets exist -- that is the same reason
  # SECRET_KEY_BASE_DUMMY has to be set in Dockerfile.deploy. An earlier version
  # of this file raised on a blank REDIS_URL and broke the build at
  # `rake vite:build_all` with "REDIS_URL is not set".
  #
  # Falling back to redis-rb's own default host/port restores the previous
  # behaviour exactly: Redis.new never connects on instantiation, so a genuinely
  # missing URL surfaces at the first real command instead of at boot.
  FALLBACK_URL = 'redis://127.0.0.1:6379'.freeze

  def self.url
    @url ||= begin
      raw = AppSecrets.redis[:url].presence || ENV['REDIS_URL'].presence || FALLBACK_URL

      uri = URI.parse(raw)
      uri.path = "/#{(ENV['REDIS_DB'].presence || DEFAULT_DB).to_i}"
      uri.to_s
    end
  end

  # True when we are running on the fallback, i.e. nothing configured a URL.
  def self.configured?
    (AppSecrets.redis[:url].presence || ENV['REDIS_URL'].presence).present?
  end

  # Host/port/db only -- safe to log, no credentials.
  def self.describe
    uri = URI.parse(url)
    "#{uri.host}:#{uri.port}#{uri.path}"
  end
end

$redis = Redis.new(url: PPRedis.url)
