# frozen_string_literal: true

# Rack::Attack — throttling for the two surfaces an anonymous client can make
# expensive. Scope is deliberately narrow and there is NO global request cap:
#
#   * The post-deploy hook walks 46 URLs in seconds from one IP
#     (.kamal/hooks/post-deploy -> rake smoke:routes). A global cap low enough to
#     be useful would 429 that walk and fail every deploy.
#   * Country and PA pages are legitimately slow and are crawled; a cap tuned for
#     them would be too high to protect anything.
#
# WCMC staff reach this through a shared office/VPN egress, so a whole team can
# arrive as ONE IP. Every limit below is sized for "a team behind one address",
# not for a single person, and the admin rule counts failed logins rather than
# ordinary admin work for exactly that reason.
Rack::Attack.enabled = ActiveModel::Type::Boolean.new.cast(ENV.fetch('RACK_ATTACK_ENABLED', 'true'))

# Rack::Attack::Request subclasses ::Rack::Request, which has no #remote_ip —
# calling it raises NoMethodError and turns every guarded request into a 500.
# Rack::Request#ip is wrong too: behind kamal-proxy and Cloudflare that is the
# proxy, so every client on earth would share one counter.
#
# ActionDispatch::RemoteIp (middleware index 7) runs before Rack::Attack (22), so
# the resolved client address is in env by the time a throttle is evaluated.
class Rack::Attack::Request < ::Rack::Request
  def remote_ip
    @remote_ip ||= (env['action_dispatch.remote_ip'] || ip).to_s
  end

  def admin?
    path.start_with?('/admin')
  end

  # Sidekiq's dashboard polls this on a timer (web/views/dashboard.erb sets
  # `updateUrl: "#{root_path}stats"`), so an open dashboard generates steady
  # traffic under /admin with no user action at all.
  def sidekiq_poll?
    path.start_with?('/admin/sidekiq') && path.end_with?('/stats')
  end
end

# See the note in docs/known-issues.md: Rails.cache is memcached in staging and
# production (evicts under exactly the pressure a throttle exists for),
# :memory_store in development (not shared across Puma workers) and :null_store
# in test (counters never increment, so throttle tests would pass vacuously).
#
# Assigned in after_initialize because config/initializers load alphabetically:
# this file runs BEFORE redis.rb, so PPRedis does not exist yet.
Rails.application.config.after_initialize do
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: PPRedis.url)
end

# Download generation. Each unique request enqueues a Sidekiq job that writes a
# multi-GB artefact; the Redis lock in Download::Requesters::Base dedupes only
# IDENTICAL requests, so varying a filter sidesteps it entirely.
#
# 60/min, not 10: one person taking CSV + SHP + GDB + PDF of a result is already
# 4, and a shared egress multiplies that by the number of colleagues working at
# once. This is a runaway-script cap, not a per-person quota.
#
# GET /downloads/poll is NOT throttled — the frontend polls it every few seconds
# while a download builds, and the smoke walk hits it too.
Rack::Attack.throttle('downloads/create by ip', limit: 60, period: 1.minute) do |req|
  req.remote_ip if req.post? && req.path.match?(%r{\A/(?:[a-z]{2}/)?downloads\z})
end

# Admin brute force.
#
# NOT a cap on admin requests. An earlier version throttled all of /admin at
# 20/min per IP, which was wrong twice over: Sidekiq's dashboard poll would eat
# the budget while idle, and a team editing CMS pages from one VPN address would
# lock itself out. Legitimate admin work is unbounded here.
#
# What is counted is FAILED AUTHENTICATION: the tracker middleware below reports
# every 401 under /admin, and an address is banned once it produces MAXRETRY of
# them inside FINDTIME. Successful requests never count, so heavy editing is free
# however many people are behind the address.
ADMIN_AUTH_MAXRETRY = 20
ADMIN_AUTH_FINDTIME = 10.minutes
ADMIN_AUTH_BANTIME  = 15.minutes

Rack::Attack.blocklist('admin auth brute force') do |req|
  next false unless req.admin?

  # Block returns false, so this only reports the current ban state; it never
  # increments. Incrementing happens in the tracker, on a real 401.
  Rack::Attack::Fail2Ban.filter(
    "admin-auth:#{req.remote_ip}",
    maxretry: ADMIN_AUTH_MAXRETRY, findtime: ADMIN_AUTH_FINDTIME, bantime: ADMIN_AUTH_BANTIME
  ) { false }
end

# Counts 401s under /admin. Runs INSIDE Rack::Attack (inserted after it), so it
# sees the response the app actually returned — which is the only way to tell a
# failed login from ordinary admin traffic. Sidekiq's dashboard poll is exempt:
# a 401 there is the same stale-session case as any other page, and counting it
# would re-introduce the self-throttling this design exists to avoid.
class AdminAuthFailureTracker
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)

    if status == 401
      req = Rack::Attack::Request.new(env)
      if req.admin? && !req.sidekiq_poll?
        Rack::Attack::Fail2Ban.filter(
          "admin-auth:#{req.remote_ip}",
          maxretry: ADMIN_AUTH_MAXRETRY, findtime: ADMIN_AUTH_FINDTIME, bantime: ADMIN_AUTH_BANTIME
        ) { true }
      end
    end

    [status, headers, body]
  end
end

Rails.application.config.middleware.insert_after(Rack::Attack, AdminAuthFailureTracker)

# Plain 429 with Retry-After. No custom body: the admin surfaces are not our UI,
# and the download endpoint is consumed by fetch(), which reads the status.
Rack::Attack.throttled_responder = lambda do |req|
  retry_after = (req.env['rack.attack.match_data'] || {})[:period].to_i
  [429, { 'Content-Type' => 'text/plain', 'Retry-After' => retry_after.to_s },
   ["Too many requests. Retry in #{retry_after}s.\n"]]
end

Rack::Attack.blocklisted_responder = lambda do |_req|
  [403, { 'Content-Type' => 'text/plain' },
   ["Too many failed sign-in attempts. Try again later.\n"]]
end

%w[throttle blocklist].each do |event|
  ActiveSupport::Notifications.subscribe("#{event}.rack_attack") do |_name, _start, _finish, _id, payload|
    req = payload[:request]
    Rails.logger.warn(
      "[rack-attack] #{event} #{req.env['rack.attack.matched']} " \
      "ip=#{req.remote_ip} path=#{req.path} method=#{req.request_method}"
    )
  end
end
