require 'timeout'

class Download::Generators::Pdf < Download::Generators::Base
  include Routeable

  TYPE = 'pdf'

  # rasterize.js bounds its own waits at PDF_NAVIGATION_TIMEOUT_MS (60s, just
  # fetching the HTML) plus PDF_READY_TIMEOUT_MS (the whole render) - this wraps
  # the entire node/Puppeteer subprocess in a hard ceiling above that combined
  # worst case (plus browser launch and PDF/zip writing), so a wedged Chromium
  # (OS-level hang, zombie process) can't tie up a Sidekiq thread - and the
  # Chromium process it's holding - forever. Raise this alongside
  # PDF_READY_TIMEOUT_MS, never below it, or this kills renders that were still
  # legitimately in progress. docker-compose.yml raises both for local dev.
  RASTERIZE_TIMEOUT_SECONDS = ENV.fetch('PDF_RASTERIZE_TIMEOUT_SECONDS', 240).to_i

  def initialize(zip_path, identifier)
    @zip_path = zip_path
    @identifier = identifier
  end

  def generate
    rasterizer = Rails.root.join('app/frontend/backend-scripts', 'rasterize.js')
    url = url_for(params)

    clear_stale_artefacts
    run_rasterizer(rasterizer, url)

    # Can reuse shared methods? TODO
    raise "Failed to add #{dest_pdf} to #{@zip_path}" unless run_zip("-j #{@zip_path} #{dest_pdf}")
    raise "Failed to add attachments to #{@zip_path}" unless add_attachments

    true
  ensure
    # The rendered PDF only exists to be zipped. Nothing removed it before, so
    # every download ever generated left a ~1MB file behind in tmp/ forever.
    FileUtils.rm_f dest_pdf
  end

  private

  # An earlier attempt that died after the archive was created (a raise in the
  # S3 upload, a killed container) leaves the archive in tmp/, and `zip` then
  # reports "nothing to do" for files it already holds. Starting from a clean
  # slate keeps a retry a real retry, and keeps a half-written PDF from a killed
  # rasterizer out of the archive.
  def clear_stale_artefacts
    FileUtils.rm_f [@zip_path, dest_pdf]
  end

  # Spawned with pgroup: true so the process we launch becomes its own process
  # group leader; on timeout we kill that whole group (`-pid`), not just the
  # `node` PID, so the Chromium child it spawned dies too instead of leaking
  # as an orphaned process.
  def run_rasterizer(rasterizer, url)
    pid = Process.spawn('node', '--trace-warnings', rasterizer.to_s, url, dest_pdf.to_s, pgroup: true)

    begin
      Timeout.timeout(RASTERIZE_TIMEOUT_SECONDS) { Process.wait(pid) }
    rescue Timeout::Error
      begin
        Process.kill('KILL', -pid)
        Process.wait(pid)
      rescue Errno::ESRCH, Errno::ECHILD
        # already gone / already reaped
      end
      raise "PDF rasterizer timed out after #{RASTERIZE_TIMEOUT_SECONDS}s for #{url}"
    end

    raise "PDF rasterizer exited with status #{$?.exitstatus} for #{url}" unless $?.success?
  end

  # Puppeteer runs inside this same app container, requesting the page from
  # itself - MAILER_HOST (Routeable's default, meant for links a user clicks
  # from their own machine, e.g. `host.docker.internal` in dev) can't reliably
  # hairpin back into the container it came from. PDF_RASTERIZER_HOST is the
  # internal address (e.g. the docker-compose service name) for this
  # container-to-itself request; falls back to the normal host when unset
  # (e.g. production, where the app's own host works fine either way).
  def default_url_options
    { host: ENV['PDF_RASTERIZER_HOST'].presence || super[:host] }
  end

  # Remove extension and add the pdf one
  def dest_pdf
    @zip_path[0..-5] << '.pdf'
  end

  def params
    {
      'controller' => controller,
      'action' => :show,
      key => @identifier,
      'for_pdf' => true
    }
  end

  def key
    id_is_integer? ? 'id' : 'iso'
  end

  def controller
    return 'protected_areas' if id_is_integer?
    @identifier.length == 3 ? 'country' : 'region'
  end

  def id_is_integer?
    # 'a-non-numeric-string'.to_i == 0
    # 0.to_s != 'a-non-numeric-string'
    @identifier.to_i.to_s == @identifier
  end
end
