namespace :pp do
  namespace :portal do
    desc "Run portal-backed WDPA release. Usage: rake pp:portal:release['WDPA_YYYY_MM']"
    task :release, [:label] => :environment do |_t, args|
      label = args[:label] || Time.now.utc.strftime('WDPA_%Y_%m')
      PortalRelease::Service.new(label: label).run!
    end

    desc 'Abort current in-flight release (drops staging tables)'
    task :abort => :environment do
      PortalRelease::Service.abort_current!
    end

    desc 'Rollback last swapped release (noop until Step 4)'
    task :rollback => :environment do
      PortalRelease::Service.rollback_last!
    end

    desc 'Show release status summary'
    task :status => :environment do
      puts PortalRelease::Service.status_report
    end
  end
end

