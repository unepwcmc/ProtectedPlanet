# frozen_string_literal: true

module PortalRelease
  class Manifest
    def initialize(release, log)
      @release = release
      @log = log
    end

    def write!
      manifest = {
        label: @release.label,
        generated_at: Time.now.utc.iso8601,
        counts: {
          staging_protected_areas: count(::Staging::ProtectedArea.table_name),
          staging_protected_area_parcels: count(::Staging::ProtectedAreaParcel.table_name),
          staging_sources: count(::Staging::Source.table_name)
        }
      }

      path = Rails.root.join('public', 'manifests')
      FileUtils.mkdir_p(path)
      file = path.join("#{@release.label}.json")
      File.write(file, JSON.pretty_generate(manifest))
      @release.update!(manifest_url: "/manifests/#{@release.label}.json")
      @log.event('manifest_written', payload: { url: @release.manifest_url })
    end

    private

    def count(table)
      ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{table}").to_i
    end
  end
end

