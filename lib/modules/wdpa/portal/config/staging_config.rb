# TO_BE_DELETED_STEP_1: This configuration should be removed once Step 1 materialized views are ready
# This file provides centralized configuration for portal import staging tables and test mode

module Wdpa
	module Portal
		module Config
			class StagingConfig

				def self.test_mode?
					ENV['WDPA_PORTAL_TEST_MODE'] == 'true'
				end

				def self.dummy_data_count
					5000
				end

				def self.batch_import_protected_areas_from_view_size
					500
				end

				# Staging table configuration
				def self.staging_table_index_prefix
					"staging"
				end

				def self.generate_staging_index_name(original_index_name)
					"#{staging_table_index_prefix}_#{original_index_name}"
				end

				# Portal view names (TODO_IMPORT: Verify these match what Step 1 developer creates)
				PORTAL_VIEWS = {
					"polygons" => "portal_standard_polygons",
					"points" => "portal_standard_points",
					"sources" => "portal_standard_sources"
				}

				def self.portal_view_for(type)
					PORTAL_VIEWS[type]
				end

				def self.portal_views_exist?
					PORTAL_VIEWS.values.all? { |view| ActiveRecord::Base.connection.table_exists?(view) }
				end

				def self.portal_views
					PORTAL_VIEWS.values
				end
 
				# All staging and live table name related configurations
				# Make sure all values are unique and do not conflict with live table names
				def self.staging_live_tables_hash
					{
						Source.table_name => StagingSource.table_name,
						ProtectedArea.table_name => StagingProtectedArea.table_name,
						ProtectedAreaParcel.table_name => StagingProtectedAreaParcel.table_name,
						# Add junction tables:
    				"countries_protected_areas" => "staging_countries_protected_areas",
						"protected_areas_sources" => "staging_protected_areas_sources"
					}
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

				def self.staging_tables_exist?
					staging_live_tables_hash.values.all? { |table| ActiveRecord::Base.connection.table_exists?(table) }
				end
			end
		end
	end
end
