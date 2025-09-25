# frozen_string_literal: true

module PortalRelease
  # Shared lock key for release process coordination
  LOCK_KEY = 42_000_001

  class Lock
    # Check if the lock is available (non-blocking)
    # Returns true if lock is available, false if already held
    def self.lock_available?
      result = ActiveRecord::Base.connection.select_value("SELECT pg_try_advisory_lock(#{PortalRelease::LOCK_KEY})")
      
      if ActiveModel::Type::Boolean.new.cast(result)
        # We got the lock, which means it was available
        # Release it immediately since we were just checking
        ActiveRecord::Base.connection.execute("SELECT pg_advisory_unlock(#{PortalRelease::LOCK_KEY})")
        true
      else
        # We couldn't get the lock, which means it's already held
        false
      end
    end

    def acquire!(release, log, notify)
      got = ActiveRecord::Base.connection.select_value("SELECT pg_try_advisory_lock(#{PortalRelease::LOCK_KEY})")
      raise 'Another release is running' unless ActiveModel::Type::Boolean.new.cast(got)

      log.event('lock_acquired')
      notify.started(release.label)
    end

    def release!(log)
      ActiveRecord::Base.connection.execute("SELECT pg_advisory_unlock(#{PortalRelease::LOCK_KEY})")
      log.event('lock_released')
    end
  end
end

