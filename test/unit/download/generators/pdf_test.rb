require 'test_helper'

# Covers Download::Generators::Pdf#run_rasterizer -- specifically the guard that
# keeps a wedged Chromium from holding a Sidekiq thread (and a ~440MB browser)
# forever: on Timeout::Error the generator SIGKILLs the whole process group
# (`-pid`), not just the `node` PID it spawned.
#
# The group kill is the part worth testing for real rather than through mocks:
# killing the node PID alone leaves Chromium orphaned and running, which is the
# exact failure this code exists to prevent, and no expectation on
# `Process.kill` can tell the two apart convincingly. So the process-group test
# spawns a real parent-with-a-background-child (the same shape as node ->
# Chromium), hands its PID to the generator, and asserts that BOTH are gone
# afterwards.
class DownloadGeneratorsPdfTest < ActiveSupport::TestCase
  ZIP_PATH = './pdf-generator-test.zip'.freeze
  URL = 'http://protectedplanet-web:3000/1234?for_pdf=true'.freeze
  # Tests that stub BOTH Process.kill and Process.wait never touch the OS with
  # the pid, so they use this rather than spawning a real process to stand in.
  UNSIGNALLED_PID = 999_999

  def setup
    @spawned_pids = []
  end

  # Anything the test spawned that a failing assertion left behind. Killing the
  # group (not the pid) mirrors the code under test, so a leaked background
  # child goes too.
  def teardown
    without_leaking_child_status do
      @spawned_pids.each do |pid|
        Process.kill('KILL', -pid)
        Process.wait(pid)
      rescue Errno::ESRCH, Errno::ECHILD, Errno::EPERM
        # already dead / already reaped
      end
    end
  end

  # The call under test reaps a real child, so its `$?` is kept out of the main
  # thread (see without_leaking_child_status in test_helper.rb) -- otherwise
  # this file's exit statuses leak into whatever test runs next.
  def run_rasterizer(gen = generator, url = URL)
    without_leaking_child_status { gen.send(:run_rasterizer, rasterizer, url) }
  end

  def generator
    Download::Generators::Pdf.new(ZIP_PATH.dup, '1234')
  end

  def rasterizer
    Rails.root.join('app/frontend/backend-scripts', 'rasterize.js')
  end

  def process_alive?(pid)
    Process.kill(0, pid)
    !zombie?(pid)
  rescue Errno::ESRCH
    false
  rescue Errno::EPERM
    # Still there, just no longer ours to signal (reparented after its parent died).
    true
  end

  # A killed child whose parent has already gone is reparented to PID 1, and in a
  # container with no init reaping for it that corpse lingers as a zombie: still
  # signalable, so kill(0) succeeds, but no longer running anything.
  def zombie?(pid)
    `ps -o state= -p #{pid}`.strip.start_with?('Z')
  end

  def wait_until(timeout: 5)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
    until yield
      flunk "condition not met within #{timeout}s" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
      sleep 0.02
    end
  end

  # Spawns a real process group leader that starts a background child and then
  # waits, so the child is a sibling process in the same group -- structurally
  # what `node rasterize.js` plus the Chromium it launches looks like to us.
  # Returns [parent_pid, child_pid].
  def spawn_group_with_background_child
    pid_path = Rails.root.join('tmp', "pdf_rasterizer_test_#{Process.pid}_#{@spawned_pids.size}.pid")
    FileUtils.rm_f(pid_path)

    parent_pid = Process.spawn(
      'sh', '-c', "sleep 300 & echo $! > #{pid_path}; wait",
      pgroup: true, in: File::NULL, out: File::NULL, err: File::NULL
    )
    @spawned_pids << parent_pid

    wait_until { File.exist?(pid_path) && !File.read(pid_path).strip.empty? }
    child_pid = File.read(pid_path).strip.to_i
    FileUtils.rm_f(pid_path)

    [parent_pid, child_pid]
  end

  # A real, already-finished-or-about-to-finish child, so `Process.wait` sets a
  # genuine `$?` instead of the test inheriting some unrelated status.
  def spawn_exiting_with(status)
    pid = Process.spawn('sh', '-c', "exit #{status}", pgroup: true)
    @spawned_pids << pid
    pid
  end

  # ---------------------------------------------------------------------------
  # spawn
  # ---------------------------------------------------------------------------

  test '#run_rasterizer spawns node as its own process group leader' do
    pid = spawn_exiting_with(0)

    # pgroup: true is the whole basis of the kill below -- without it the
    # generator would be signalling whatever group Sidekiq itself runs in.
    Process.expects(:spawn)
           .with('node', '--trace-warnings', rasterizer.to_s, URL, './pdf-generator-test.pdf', pgroup: true)
           .returns(pid)

    run_rasterizer
  end

  # ---------------------------------------------------------------------------
  # Timeout::Error -> kill(-pid)
  # ---------------------------------------------------------------------------

  test '#run_rasterizer, on timeout, kills the whole process group so an orphaned Chromium cannot survive' do
    parent_pid, child_pid = spawn_group_with_background_child
    assert process_alive?(child_pid), 'test fixture: background child should be running before the kill'

    Process.stubs(:spawn).returns(parent_pid)
    Timeout.stubs(:timeout).raises(Timeout::Error)

    assert_raises(RuntimeError) { run_rasterizer }

    wait_until { !process_alive?(child_pid) }
    assert_not process_alive?(child_pid),
      'the background child survived the timeout -- kill(pid) instead of kill(-pid) leaks a wedged Chromium'
  end

  test '#run_rasterizer, on timeout, reaps the killed process instead of leaving a zombie' do
    parent_pid, = spawn_group_with_background_child

    Process.stubs(:spawn).returns(parent_pid)
    Timeout.stubs(:timeout).raises(Timeout::Error)

    assert_raises(RuntimeError) { run_rasterizer }

    # Already reaped by run_rasterizer's own Process.wait, so there is no child
    # left for the test process to wait on.
    assert_raises(Errno::ECHILD) { Process.wait(parent_pid) }
  end

  test '#run_rasterizer, on timeout, raises naming the ceiling and the URL' do
    pid, = spawn_group_with_background_child

    Process.stubs(:spawn).returns(pid)
    Timeout.stubs(:timeout).raises(Timeout::Error)

    error = assert_raises(RuntimeError) { run_rasterizer }

    assert_includes error.message, Download::Generators::Pdf::RASTERIZE_TIMEOUT_SECONDS.to_s
    assert_includes error.message, URL
  end

  test '#run_rasterizer, on timeout, uses the timeout constant as the ceiling' do
    Process.stubs(:spawn).returns(UNSIGNALLED_PID)
    Timeout.expects(:timeout)
           .with(Download::Generators::Pdf::RASTERIZE_TIMEOUT_SECONDS)
           .raises(Timeout::Error)
    Process.stubs(:kill)
    Process.stubs(:wait)

    assert_raises(RuntimeError) { run_rasterizer }
  end

  # The process group can be gone by the time the timeout fires (it exited in
  # the gap, or a previous signal already took it). That must not replace the
  # timeout error with a confusing ESRCH/ECHILD, which would lose the reason the
  # job actually failed.
  test '#run_rasterizer, on timeout, still raises the timeout error when the group is already gone' do
    Process.stubs(:spawn).returns(UNSIGNALLED_PID)
    Timeout.stubs(:timeout).raises(Timeout::Error)
    Process.stubs(:kill).raises(Errno::ESRCH)

    error = assert_raises(RuntimeError) { run_rasterizer }
    assert_includes error.message, 'PDF rasterizer timed out'
  end

  test '#run_rasterizer, on timeout, still raises the timeout error when the process was already reaped' do
    Process.stubs(:spawn).returns(UNSIGNALLED_PID)
    Timeout.stubs(:timeout).raises(Timeout::Error)
    Process.stubs(:kill)
    Process.stubs(:wait).raises(Errno::ECHILD)

    error = assert_raises(RuntimeError) { run_rasterizer }
    assert_includes error.message, 'PDF rasterizer timed out'
  end

  # ---------------------------------------------------------------------------
  # exit status
  # ---------------------------------------------------------------------------

  test '#run_rasterizer raises when the rasterizer exits non-zero' do
    # Spawn BEFORE stubbing: Ruby evaluates `.returns(...)`'s argument after
    # `.stubs(:spawn)` has already replaced Process.spawn, so an inline helper
    # call here would be the stub returning nil, not a real pid.
    pid = spawn_exiting_with(3)
    Process.stubs(:spawn).returns(pid)

    error = assert_raises(RuntimeError) { run_rasterizer }
    assert_includes error.message, 'exited with status 3'
    assert_includes error.message, URL
  end

  test '#run_rasterizer returns without raising when the rasterizer exits zero' do
    pid = spawn_exiting_with(0)
    Process.stubs(:spawn).returns(pid)

    assert_nothing_raised { run_rasterizer }
  end

  # ---------------------------------------------------------------------------
  # PDF_RASTERIZER_HOST
  # ---------------------------------------------------------------------------

  test '#default_url_options uses PDF_RASTERIZER_HOST when set' do
    ENV.stubs(:[]).with('PDF_RASTERIZER_HOST').returns('protectedplanet-web:3000')

    assert_equal 'protectedplanet-web:3000', generator.send(:default_url_options)[:host]
  end

  # Kamal deployments are expected to leave it unset; MAILER_HOST has to carry
  # the render there, so the fallback is load-bearing, not a nicety.
  test '#default_url_options falls back to the mailer host when PDF_RASTERIZER_HOST is unset' do
    ENV.stubs(:[]).with('PDF_RASTERIZER_HOST').returns(nil)

    expected = Rails.application.config.action_mailer.default_url_options[:host]
    assert_equal expected, generator.send(:default_url_options)[:host]
  end

  test '#default_url_options falls back to the mailer host when PDF_RASTERIZER_HOST is blank' do
    ENV.stubs(:[]).with('PDF_RASTERIZER_HOST').returns('')

    expected = Rails.application.config.action_mailer.default_url_options[:host]
    assert_equal expected, generator.send(:default_url_options)[:host]
  end
end
