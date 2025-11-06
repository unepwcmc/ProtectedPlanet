# frozen_string_literal: true

module Wdpa
  module Portal
    module Config
      class PortalImportConfig
        # ============================================================================
        # CONSTANTS
        # ============================================================================

        STAGING_PREFIX = 'staging_'
        BACKUP_PREFIX = 'bk'

        # This view is created by PortalRelease::Preflight.create_portal_downloads_view! in app/services/portal_release/preflight.rb
        PORTAL_DOWNALOAD_VIEWS = "portal_downloads_protected_areas"

        # ============================================================================
        # CONFIGURATION VALUES
        # ============================================================================

        def self.batch_import_protected_areas_from_view_size
          10
        end

        # Database operation timeouts (in milliseconds)
        def self.lock_timeout_ms
          30_000 # 30 seconds
        end

        def self.statement_timeout_ms
          300_000 # 5 minutes
        end

        # Number of backups to keep when cleaning up old backups
        def self.keep_backup_count
          1
        end

        # Progress notification settings for large imports
        def self.progress_notification_interval
          # Send progress update every N records
          50000
        end

        def self.progress_notifications_enabled?
          # Enable/disable progress notifications (default: true)
          ENV['PP_IMPORT_PROGRESS_NOTIFICATIONS'] != 'false'
        end

        # ============================================================================
        # TABLE DEFINITIONS
        # ============================================================================

        # Independent tables - no foreign key dependencies
        # Make sure all values are unique and do not conflict with live table names
        # These tables can be created/swapped first as they don't reference other tables
        def self.independent_table_names
          {
            Source.table_name => Staging::Source.table_name,
            GreenListStatus.table_name => Staging::GreenListStatus.table_name,
            NoTakeStatus.table_name => Staging::NoTakeStatus.table_name,
            CountryStatistic.table_name => Staging::CountryStatistic.table_name,
            GlobalStatistic.table_name => Staging::GlobalStatistic.table_name,
            PameEvaluation.table_name => Staging::PameEvaluation.table_name,
            PameSource.table_name => Staging::PameSource.table_name,
            PameStatistic.table_name => Staging::PameStatistic.table_name,
            StoryMapLink.table_name => Staging::StoryMapLink.table_name
          }
        end

        # Main entity tables - referenced by junction tables
        # Make sure all values are unique and do not conflict with live table names
        # These tables are referenced by junction tables, so they must exist before junction tables
        def self.main_entity_tables
          {
            ProtectedArea.table_name => Staging::ProtectedArea.table_name,
            ProtectedAreaParcel.table_name => Staging::ProtectedAreaParcel.table_name
          }
        end

        # Junction tables - reference main entity tables
        # Make sure all values are unique and do not conflict with live table names
        # These MUST come last as they have foreign keys pointing to main entities
        def self.junction_tables
          {
            # Junction tables for countries
            Country.countries_pas_junction_table_name => Country.staging_countries_pas_junction_table_name,
            Country.countries_pa_parcels_junction_table_name => Country.staging_countries_pa_parcels_junction_table_name,
            Country.countries_pame_evaluations_junction_table_name => Country.staging_countries_pame_evaluations_junction_table_name,

            # Junction tables for sources
            Source.protected_areas_sources_junction_table_name => Staging::Source.protected_areas_sources_junction_table_name,
            Source.protected_area_parcels_sources_junction_table_name => Staging::Source.protected_area_parcels_sources_junction_table_name
          }
        end

        # ============================================================================
        # TABLE NAME GENERATION UTILITIES
        # ============================================================================

        def self.generate_staging_table_index_name(original_name)
          "#{STAGING_PREFIX}#{original_name}"
        end

        def self.generate_live_table_index_name_from_staging(staging_index_name)
          staging_index_name.gsub(/^#{STAGING_PREFIX}/, '')
        end

        def self.generate_backup_name(original_name, timestamp)
          "#{BACKUP_PREFIX}#{timestamp}_#{original_name}"
        end

        # ============================================================================
        # BACKUP TABLE UTILITIES
        # ============================================================================

        def self.is_backup_table?(table_name)
          table_name.match?(/^#{BACKUP_PREFIX}\d{10}_.+$/)
        end

        def self.extract_backup_timestamp(table_name)
          table_name.match(/^#{BACKUP_PREFIX}(\d{10})_/)[1]
        end

        def self.extract_table_name_from_backup(table_name)
          table_name.gsub(/^#{BACKUP_PREFIX}\d{10}_/, '')
        end

        def self.remove_backup_suffix(name)
          name.gsub(/^#{BACKUP_PREFIX}\d{10}_/, '')
        end

        # ============================================================================
        # TABLE NAME RESOLUTION UTILITIES
        # ============================================================================

        # All staging and live table name related configurations
        def self.staging_live_tables_hash
          independent_table_names.merge(main_entity_tables).merge(junction_tables)
        end

        def self.staging_tables
          staging_live_tables_hash.values
        end

        def self.get_live_table_name_from_staging_name(staging_table)
          staging_live_tables_hash.invert[staging_table]
        end

        def self.get_staging_table_name_from_live_table(live_table)
          staging_live_tables_hash[live_table]
        end

        # ============================================================================
        # PORTAL VIEW UTILITIES
        # ============================================================================

        # All staging and live table name related configurations
        # It has to in this order as 
        def self.portal_materialised_views_hash
          {
            iso3_agg: {
              live: 'portal_iso3_agg',
              staging: 'staging_portal_iso3_agg'
            },
            parent_iso3_agg: {
              live: 'portal_parent_iso3_agg',
              staging: 'staging_portal_parent_iso3_agg'
            },
            int_crit_agg: {
              live: 'portal_int_crit_agg',
              staging: 'staging_portal_int_crit_agg'
            },
            polygons: {
              live: 'portal_standard_polygons',
              staging: 'staging_portal_standard_polygons'
            },
            points: {
              live: 'portal_standard_points',
              staging: 'staging_portal_standard_points'
            },
            sources: {
              live: 'portal_standard_sources',
              staging: 'staging_portal_standard_sources'
            },
          }
        end

        def self.get_live_materialised_view_name_from_staging(staging_name)
          mapping = portal_materialised_views_hash
          entry = mapping.values.find { |v| v[:staging] == staging_name }
          entry ? entry[:live] : nil
        end

        def self.get_staging_materialised_view_name_from_live(live_name)
          mapping = portal_materialised_views_hash
          entry = mapping.values.find { |v| v[:live] == live_name }
          entry ? entry[:staging] : nil
        end

        def self.portal_live_materialised_views
          portal_materialised_views_hash.transform_values { |v| v[:live] }
        end

        def self.portal_live_materialised_view_values
          portal_live_materialised_views.values
        end

        def self.portal_staging_materialised_views
          portal_materialised_views_hash.transform_values { |v| v[:staging] }
        end

        def self.portal_staging_materialised_view_values
          portal_staging_materialised_views.values
        end

        def self.portal_protected_area_staging_materialised_views
          [portal_materialised_views_hash[:polygons][:staging], 
          portal_materialised_views_hash[:points][:staging]]
        end

        # ============================================================================
        # TABLE SWAP SEQUENCE
        # ============================================================================

        # Table swap sequence - CRITICAL: Order matters for foreign key dependencies
        #
        # The swap must happen in this specific order to avoid foreign key constraint violations:
        # 1. Independent tables first - these have no foreign key dependencies
        # 2. Main entity tables second - these are referenced by junction tables
        # 3. Junction tables last - these reference the main entity tables
        #
        # This ordering ensures that when we swap tables, the referenced tables
        # (main entities) exist before we try to swap the tables that reference them.
        def self.swap_sequence_live_table_names
          @swap_sequence_live_table_names ||= independent_table_names.keys + main_entity_tables.keys + junction_tables.keys
        end
      end
    end
  end
end
