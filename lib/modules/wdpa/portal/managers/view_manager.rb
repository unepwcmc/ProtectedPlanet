# frozen_string_literal: true

module Wdpa
  module Portal
    module Managers
      class ViewManager
        # Create staging materialized views by running the canonical FDW_VIEWS.sql script
        # Then refresh all staging materialized views
        def self.ensure_staging_materialized_views!
          fdw_file = Rails.root.join('FDW_VIEWS.sql')
          raise "FDW_VIEWS.sql not found at #{fdw_file}" unless File.exist?(fdw_file)

          # Create the needed materialised views as well as refresh to get the data (in the sql script)
          Rails.logger.info "Creating/refreshing staging materialized views by executing FDW_VIEWS.sql"
          sql = File.read(fdw_file)
          ActiveRecord::Base.connection.execute(sql)

          # Validate that all required staging views exist after execution (hard error if missing)
          unless validate_required_views_exist
            raise 'Failed to create required staging materialized views. FDW_VIEWS.sql execution may have failed.'
          end

          Rails.logger.info "✅ All required staging materialized views created successfully"
        end

        def self.materialized_view_exists?(view_name)
          sql = <<~SQL
            SELECT 1
            FROM pg_matviews
            WHERE schemaname = 'public' AND matviewname = '#{view_name}'
          SQL
          result = ActiveRecord::Base.connection.execute(sql)
          result.any?
        end

        # Validate that all required views exist (used by importer)
        def self.validate_required_views_exist
          required_views = Wdpa::Portal::Config::PortalImportConfig.portal_staging_materialised_view_values

          missing_views = required_views.select do |view_name|
            !materialized_view_exists?(view_name)
          end

          if missing_views.any?
            Rails.logger.error "Missing required materialized views: #{missing_views.join(', ')}"
            return false
          end

          Rails.logger.info 'All required materialized views exist'
          true
        end

        # --- SHARED INDEX RENAMING HELPERS ---
        def self.rename_materialised_view_indexes_add_backup_suffix(view_name, backup_timestamp)
          rename_materialised_view_indexes(view_name, :add_backup_suffix, backup_timestamp)
        end

        def self.rename_materialised_view_indexes_remove_backup_prefix(view_name)
          rename_materialised_view_indexes(view_name, :remove_backup_prefix)
        end

        def self.rename_materialised_view_indexes_remove_staging_prefix(view_name)
          Rails.logger.info "Renaming indexes to remove staging_ prefix on #{view_name}"
          rename_materialised_view_indexes(view_name, :remove_staging_prefix)
        end

        def self.rename_materialised_view_indexes_add_staging_prefix(view_name)
          Rails.logger.info "Renaming indexes to add staging_ prefix on #{view_name}"
          rename_materialised_view_indexes(view_name, :add_staging_prefix)
        end

        # Shared implementation used by both public helpers above
        def self.rename_materialised_view_indexes(view_name, action, backup_timestamp = nil)
          conn = ActiveRecord::Base.connection
          sql = <<~SQL
            SELECT indexname
            FROM pg_indexes
            WHERE schemaname = 'public' AND tablename = #{conn.quote(view_name)}
          SQL
          indexes = conn.execute(sql).to_a
          return if indexes.empty?

          indexes.each do |row|
            old_name = row['indexname']
            new_name = case action
                       when :add_backup_suffix
                         raise ArgumentError, 'backup_timestamp required' unless backup_timestamp
                         Wdpa::Portal::Config::PortalImportConfig.generate_backup_name(old_name, backup_timestamp)
                       when :remove_backup_prefix
                         Wdpa::Portal::Config::PortalImportConfig.remove_backup_suffix(old_name)
                       when :add_staging_prefix
                         prefix = Wdpa::Portal::Config::PortalImportConfig::STAGING_PREFIX
                         old_name.start_with?(prefix) ? old_name : "#{prefix}#{old_name}"
                       when :remove_staging_prefix
                         prefix = Wdpa::Portal::Config::PortalImportConfig::STAGING_PREFIX
                         old_name.start_with?(prefix) ? old_name.delete_prefix(prefix) : old_name
                       else
                         raise ArgumentError, "Unknown action: #{action}"
                       end
            Rails.logger.debug "Renaming index #{old_name} -> #{new_name} on #{view_name}"
            next if new_name == old_name
            conn.execute("ALTER INDEX #{old_name} RENAME TO #{new_name}")
          end
        end
      end
    end
  end
end
