require 'net/http'

# Ruby-owned lifetime for the long-lived headless Chrome that the `pdf` capsule's
# jobs render in. Started and stopped from Sidekiq's own lifecycle hooks (see
# config/initializers/sidekiq.rb), which replaces the bash supervisor that used
# to wrap the container command.
#
# Why Ruby owns it rather than a wrapper script:
#   - Chrome is spawned by THIS process, so Process.waitpid reaps it. A wrapper
#     that `exec`s Sidekiq makes Sidekiq PID 1, and Sidekiq never reaps
#     processes it did not spawn.
#   - start/stop follow Sidekiq's own :startup / :shutdown events instead of
#     shell signal handling.
#   - the container command goes back to a plain `bundle exec sidekiq`.
#
# Chrome stays in the same container as the workers because it has to:
# rasterize.js connects to http://127.0.0.1:PORT, and Chrome refuses to bind its
# DevTools port to anything but loopback -- it silently ignores
# --remote-debugging-address=0.0.0.0 -- so a sibling container cannot reach it
# without a socat shim.
#
# Chrome is ALWAYS best-effort, never a dependency. rasterize.js launches a
# private browser whenever it cannot reach this one (slower, and ~440MB heavier
# per concurrent job, but correct). Nothing here may raise into Sidekiq's boot
# or shutdown, so every public method swallows its errors after logging them.
module SharedChrome
  # Resolves the executable, loads the shared flags from chrome-args.js and
  # manages the profile dir. Reused rather than reimplemented in Ruby so the
  # shared browser and rasterize.js's private fallback cannot drift apart.
  SCRIPT = 'docker/scripts/pdf-chrome'.freeze

  # Reading these must never raise. lib/modules is in eager_load_paths
  # (config/application.rb), so the constants below are evaluated at BOOT in
  # every role -- including Puma, which never touches Chrome. A typo'd env var
  # taking the web role down with an ArgumentError would be absurd, so a value
  # that is not a positive integer falls back to the default instead.
  def self.env_int(name, default)
    parsed = Integer(ENV[name].to_s.strip, exception: false)
    parsed&.positive? ? parsed : default
  end
  private_class_method :env_int

  # Same default as rasterize.js and docker/scripts/pdf-chrome. PDF_BROWSER_PORT
  # exists only to move every end off 9222 together.
  PORT = env_int('PDF_BROWSER_PORT', 9222)

  # How long a freshly spawned Chrome gets to answer on 127.0.0.1:PORT before it
  # is treated as a failed start. Booting takes ~8s on the dev VM.
  READY_TIMEOUT_SECONDS = env_int('PDF_CHROME_READY_SECONDS', 45)

  # How often the supervisor thread looks at Chrome, and how long it waits
  # before retrying a failed start.
  CHECK_INTERVAL_SECONDS = env_int('PDF_CHROME_CHECK_SECONDS', 30)

  # A start that fails this many times in a row is not going to start. The usual
  # cause is the port being held by something else, which no amount of
  # restarting will fix -- and each attempt spawns a full browser, so retrying
  # forever burns real memory. Stop, and say so; PDFs still work.
  GIVE_UP_AFTER_FAILED_STARTS = 3

  # A Chrome can be alive and still useless: hung, deadlocked, or wedged after an
  # OOM. `exited?` cannot see that -- the process is right there -- so the
  # supervisor would leave a browser nothing can talk to running forever, with
  # every PDF quietly paying for a private one and nothing in the log after the
  # initial "ready".
  #
  # NOT acted on after a single failed probe. Under load a check can time out
  # against a perfectly healthy browser, and replacing one mid-render kills that
  # job outright (Sidekiq retries are not reliable for these). Only a browser
  # that has missed this many consecutive checks is treated as wedged -- about
  # PDF_CHROME_CHECK_SECONDS x this, so ~90s by default, which a working Chrome
  # does not do.
  WEDGED_AFTER_FAILED_PROBES = 3

  MUTEX = Mutex.new

  class << self
    # Idempotent. Returns immediately -- the browser comes up on a supervisor
    # thread, so a slow Chrome never delays Sidekiq picking up jobs.
    def start!
      return log('disabled by PDF_SHARED_CHROME') if disabled?

      MUTEX.synchronize do
        return if @supervisor&.alive?

        # Something already owns the port: a browser left behind by a previous
        # run, or one started by hand for debugging. Leave it alone rather than
        # fighting it -- a second Chrome on the same port would bind [::1] and
        # be unusable anyway.
        if reachable?
          return log("a browser is already listening on 127.0.0.1:#{PORT}; leaving it alone")
        end

        @stopping = false
        @supervisor = Thread.new { supervise }
        @supervisor.name = 'shared-chrome'
      end
    rescue StandardError => e
      log("could not start: #{e.class}: #{e.message}", :warn)
    end

    # Idempotent. Kills the process GROUP, so Chrome's renderer and crashpad
    # children go with it instead of being re-parented and stranded.
    def stop!
      @stopping = true
      pid = MUTEX.synchronize { p = @pid; @pid = nil; p }
      return if pid.nil?

      log("stopping shared Chrome (pid #{pid})")
      terminate(pid)
    rescue StandardError => e
      log("error while stopping: #{e.class}: #{e.message}", :warn)
    end

    # Whether a DevTools endpoint answers where rasterize.js will look for it.
    # Deliberately over IPv4: Chrome falls back to binding [::1] when the port
    # is taken, and rasterize.js could not reach that either.
    def reachable?
      Net::HTTP.start('127.0.0.1', PORT, open_timeout: 2, read_timeout: 3) do |http|
        http.get('/json/version').is_a?(Net::HTTPSuccess)
      end
    rescue StandardError
      false
    end

    private

    def disabled?
      %w[0 false no].include?(ENV['PDF_SHARED_CHROME'].to_s.strip.downcase)
    end

    def supervise
      consecutive_failures = 0
      failed_probes = 0

      until @stopping
        if @pid && !exited?(@pid)
          if reachable?
            failed_probes = 0
          else
            failed_probes += 1

            if failed_probes >= WEDGED_AFTER_FAILED_PROBES
              log("Chrome (pid #{@pid}) is running but has not answered on " \
                  "127.0.0.1:#{PORT} for #{failed_probes} checks; replacing it", :warn)
              terminate(@pid)
              MUTEX.synchronize { @pid = nil }
              failed_probes = 0
              next
            end
          end

          sleep CHECK_INTERVAL_SECONDS
          next
        end

        log('Chrome is gone; restarting it (PDFs use private browsers meanwhile)', :warn) if @pid
        MUTEX.synchronize { @pid = nil }

        if consecutive_failures >= GIVE_UP_AFTER_FAILED_STARTS
          log("giving up after #{consecutive_failures} failed starts; " \
              'every PDF will launch its own browser from here on', :warn)
          break
        end

        consecutive_failures = launch! ? 0 : consecutive_failures + 1
        failed_probes = 0
        sleep CHECK_INTERVAL_SECONDS
      end
    rescue StandardError => e
      # The supervisor dying silently is exactly the failure this replaces, so
      # it is logged loudly. PDFs keep working via the private-browser path.
      log("supervisor stopped: #{e.class}: #{e.message}", :warn)
    end

    # true once Chrome is up AND answering. A running Chrome is not proof of a
    # usable one -- see wait_until_reachable.
    def launch!
      return false if @stopping

      pid = Process.spawn(Rails.root.join(SCRIPT).to_s, pgroup: true, **spawn_io)

      unless wait_until_reachable(pid)
        terminate(pid)
        return false
      end

      MUTEX.synchronize { @pid = pid }
      log("ready on 127.0.0.1:#{PORT} (pid #{pid})")
      true
    rescue StandardError => e
      log("failed to launch: #{e.class}: #{e.message}", :warn)
      false
    end

    def wait_until_reachable(pid)
      deadline = now + READY_TIMEOUT_SECONDS

      loop do
        return true if reachable?

        if exited?(pid)
          log("Chrome exited before it answered on 127.0.0.1:#{PORT}", :warn)
          return false
        end

        if now >= deadline
          # Chrome does not fail when the port is taken: it binds [::1] instead
          # and looks perfectly healthy, while rasterize.js (IPv4) can never
          # reach it. Unchecked that is permanent silent degradation.
          log("Chrome is running but never answered on 127.0.0.1:#{PORT} after " \
              "#{READY_TIMEOUT_SECONDS}s -- is the port already taken?", :warn)
          return false
        end

        sleep 1
      end
    end

    def terminate(pid, grace_seconds: 10)
      signal(pid, 'TERM')
      deadline = now + grace_seconds
      sleep 0.2 until exited?(pid) || now >= deadline
      return if exited?(pid)

      log("Chrome (pid #{pid}) ignored TERM; killing", :warn)
      signal(pid, 'KILL')
      sleep 0.2 until exited?(pid) || now >= deadline + 5
    end

    # Negative pid: the whole process group. Chrome's children are group members
    # (Process.spawn used pgroup: true), so they die with it rather than being
    # re-parented to PID 1 and left as zombies.
    def signal(pid, name)
      Process.kill(name, -pid)
    rescue Errno::ESRCH, Errno::EPERM
      nil
    end

    # Reaps as a side effect -- that is the point. Returns true once the process
    # has exited and its status has been collected.
    def exited?(pid)
      !Process.waitpid(pid, Process::WNOHANG).nil?
    rescue Errno::ECHILD
      true
    end

    # Matches the wrapper's behaviour: unset means Chrome's output joins the
    # Sidekiq log (and so `kamal app logs`); PDF_CHROME_LOG splits it into a file,
    # which docker-compose does to keep the dev logs readable.
    def spawn_io
      path = ENV['PDF_CHROME_LOG'].to_s
      return {} if path.empty?

      { out: [path, 'a'], err: %i[child out] }
    end

    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def log(message, level = :info)
      logger = defined?(Sidekiq) ? Sidekiq.logger : Rails.logger
      logger&.public_send(level, "[pdf-chrome] #{message}")
    end
  end
end
