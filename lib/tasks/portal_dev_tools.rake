# frozen_string_literal: true

namespace :pp do
  namespace :portal do
    # Run the Step 2 importer directly with optional filters
    # Usage:
    #   rake pp:portal:dev:import_only["sources,protected_areas"]
    #   rake pp:portal:dev:import_only[sources]
    #   rake pp:portal:dev:import_only[sources] PP_IMPORT_SAMPLE=100
    desc 'Run portal importer with only=<list>, optional sample'
    task :"dev:import_only", [:only] => :environment do |_t, args|
      ENV['PP_IMPORT_ONLY'] = args[:only].to_s if args[:only]
      Wdpa::Portal::Importer.import(create_staging_materialized_views: false)
    end

    # Run portal importer with skip list
    #   rake pp:portal:dev:import_skip["pame,green_list"]
    desc 'Run portal importer with skip=<list>'
    task :"dev:import_skip", [:skip] => :environment do |_t, args|
      ENV['PP_IMPORT_SKIP'] = args[:skip].to_s if args[:skip]
      Wdpa::Portal::Importer.import(create_staging_materialized_views: false)
    end

    # Resume importer using checkpoints (label optional to persist in Release)
    #   rake pp:portal:dev:import_resume[label]
    desc 'Resume portal importer using checkpoints; optional label to persist in Release.stats_json'
    task :"dev:import_resume", [:label] => :environment do |_t, args|
      ENV['PP_RELEASE_LABEL'] = args[:label].to_s if args[:label]
      ENV['PP_IMPORT_CHECKPOINTS_DISABLE'] = 'false'
      Wdpa::Portal::Importer.import(create_staging_materialized_views: false)
    end

    # Resume a full release from a specific phase (default: import_core)
    #   rake pp:portal:dev:release_resume[label,phase]
    desc 'Resume portal release from a given phase (import_core by default)'
    task :"dev:release_resume", [:label, :phase] => :environment do |_t, args|
      phase = (args[:phase] || 'import_core').to_s
      ENV['PP_RELEASE_START_AT'] = phase
      Rake::Task['pp:portal:release'].invoke(args[:label])
    end
  end
end

