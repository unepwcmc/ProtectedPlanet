require 'test_helper'

# Wdpa::Portal::Checkpoint has two stores. A real release passes a release_id
# (PortalRelease::Service passes @release.id) and offsets live in that Release's
# stats_json, scoped to it. With no release_id it falls back to ONE global file
# shared by every run.
#
# reset_all! only runs as the last phase of a SUCCESSFUL release, so a crash, an
# abort, a dry run or a partial PP_RELEASE_ONLY_PHASES subset leaves offsets in
# that global file. Trusting them makes the next run skip records it never
# imported, which surfaces as "Target staging table staging_protected_areas does
# not exist or has no records" -- silent data loss, not a visible failure.
class CheckpointTest < ActiveSupport::TestCase
  FILE_PATH = Wdpa::Portal::Checkpoint::FILE_PATH

  setup do
    Wdpa::Portal::Checkpoint.instance_variable_set(:@store, nil)
    Wdpa::Portal::ImportRuntimeConfig.release_id = nil
    FileUtils.mkdir_p(File.dirname(FILE_PATH))
    File.write(FILE_PATH, '{}')
  end

  teardown do
    Wdpa::Portal::Checkpoint.instance_variable_set(:@store, nil)
    Wdpa::Portal::ImportRuntimeConfig.reset!
    File.write(FILE_PATH, '{}')
  end

  def write_file_store(hash)
    File.write(FILE_PATH, JSON.pretty_generate(hash))
    Wdpa::Portal::Checkpoint.instance_variable_set(:@store, nil)
  end

  test 'offsets left in the shared file store by an earlier run are discarded' do
    write_file_store('attributes' => { 'v_pa' => { 'cursor' => %w[999999] } })

    assert_empty Wdpa::Portal::Checkpoint.store
    assert_nil Wdpa::Portal::Checkpoint.get_cursor('v_pa'),
               'a cursor from an earlier run must not resume this one'
  end

  test 'the stale file is rewritten empty so the next run does not see it either' do
    write_file_store('geometry' => { 'v_pa' => { 'staging_protected_areas' => { 'done' => true } } })
    Wdpa::Portal::Checkpoint.store

    assert_equal({}, JSON.parse(File.read(FILE_PATH)))
  end

  # The whole point: geometry marked done by a run that then crashed must not
  # convince the next run it has nothing to do.
  test 'a geometry done flag from an earlier run does not skip work' do
    write_file_store('geometry' => { 'v_pa' => { 'staging_protected_areas' => { 'done' => true } } })

    refute Wdpa::Portal::Checkpoint.geometry_done?('v_pa', 'staging_protected_areas')
  end

  test 'an already empty file store is left alone' do
    assert_empty Wdpa::Portal::Checkpoint.store
    assert_equal({}, JSON.parse(File.read(FILE_PATH)))
  end

  # Within one process the store still accumulates normally -- discarding happens
  # on load, not on write, so an importer's own progress is still tracked.
  test 'cursors set during this run are still readable' do
    Wdpa::Portal::Checkpoint.set_cursor('v_pa', %w[42])

    assert_equal %w[42], Wdpa::Portal::Checkpoint.get_cursor('v_pa')
  end

  # Release-scoped checkpoints are the safe case and must keep resuming: those
  # offsets provably belong to that release.
  test 'release scoped checkpoints are not discarded' do
    release = Release.create!(label: 'SEP2026', state: 'importing')
    release.update_columns(stats_json: { 'checkpoints' => { 'attributes' => { 'v_pa' => { 'cursor' => %w[7] } } } })
    Wdpa::Portal::ImportRuntimeConfig.release_id = release.id
    Wdpa::Portal::Checkpoint.instance_variable_set(:@store, nil)

    assert_equal %w[7], Wdpa::Portal::Checkpoint.get_cursor('v_pa')
  end
end
