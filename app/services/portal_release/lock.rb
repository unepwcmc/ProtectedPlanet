# frozen_string_literal: true

module PortalRelease
  class Lock
    KEY = 42_000_001

    def acquire!(release, log, notify)
      got = ActiveRecord::Base.connection.select_value("SELECT pg_try_advisory_lock(#{KEY})")
      raise 'Another release is running' unless ActiveModel::Type::Boolean.new.cast(got)

      log.event('lock_acquired')
      notify.started(release.label)
    end

    def release!(log)
      ActiveRecord::Base.connection.execute("SELECT pg_advisory_unlock(#{KEY})")
      log.event('lock_released')
    end
  end
end

