require 'test_helper'
require 'connection_pool'
require 'sidekiq'

# connection_pool is only ever a transitive dependency here -- activesupport wants
# ">= 2.2.5" and sidekiq wants ">= 2.3.0", both open-ended -- so a routine
# `bundle update` silently pulled in 3.0.2, which changed TimedStack#pop from
# positional to keyword-only:
#
#   2.x  def pop(timeout = 0.5, options = {})
#   3.x  def pop(timeout: 0.5, exception: ..., **)
#
# Sidekiq 7.x still calls it positionally (`@sleeper.pop(total)` in
# Sidekiq::Scheduled::Poller#initial_wait), so every job container died at boot
# with "ArgumentError: wrong number of arguments (given 1, expected 0)". The
# poller thread never entered its loop, which meant the scheduled and retry sets
# were never polled: perform_in/perform_at silently did nothing and no failed job
# was ever retried. Nothing surfaced in the UI -- only a stack trace on stdout at
# container start, which is easy to miss.
#
# The Gemfile now pins "~> 2.5". This test is the tripwire: it fails the moment
# the contract Sidekiq relies on stops holding, rather than at the next deploy.
class SidekiqConnectionPoolTest < ActiveSupport::TestCase
  test 'TimedStack#pop accepts the positional timeout Sidekiq passes' do
    params = ConnectionPool::TimedStack.instance_method(:pop).parameters
    positional = params.select { |kind, _| %i[req opt].include?(kind) }

    assert positional.any?,
           "ConnectionPool::TimedStack#pop takes no positional argument (#{params.inspect}), " \
           'but Sidekiq::Scheduled::Poller#initial_wait calls `@sleeper.pop(total)`. ' \
           'This is the connection_pool 3.x incompatibility -- keep the Gemfile pinned to 2.x.'
  end

  test 'a positional pop against an empty stack raises TimeoutError, not ArgumentError' do
    stack = ConnectionPool::TimedStack.new(0) { nil }

    # The exact call shape Sidekiq makes. ArgumentError here means the scheduler
    # thread will die at boot.
    assert_raises(ConnectionPool::TimeoutError) { stack.pop(0.01) }
  end

  test 'sidekiq is 7.x, the major this pin is tied to' do
    # If Sidekiq goes to 8 (which supports connection_pool 3.x), the pin can and
    # should be lifted -- this assertion is the reminder.
    assert_equal 7, Gem::Version.new(Sidekiq::VERSION).segments.first,
                 'Sidekiq major changed: revisit the connection_pool "~> 2.5" pin in the Gemfile.'
  end
end
