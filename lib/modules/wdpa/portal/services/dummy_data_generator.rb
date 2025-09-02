# TO_BE_DELETED_STEP_1: This entire file should be deleted once Step 1 materialized views are ready
# This service generates dummy tables for testing purposes only
# Once Step 1 is complete, the real materialized views will be available and this file can be removed

module Wdpa
  module Portal
    module Services
      class DummyDataGenerator
        def self.generate_test_views
          return unless Wdpa::Portal::Config::StagingConfig.test_mode?
          
          Rails.logger.info "Generating dummy portal_standard_* tables for testing..."
          
          # Create dummy portal_standard_sources table first (referenced by protected areas)
          create_dummy_sources_table
          
          # Create dummy portal_standard_polygons table
          create_dummy_polygons_table
          
          # Create dummy portal_standard_points table
          create_dummy_points_table
          
          # Verify all tables were created successfully
          verify_tables_created
          
          Rails.logger.info "Dummy portal_standard_* tables created successfully"
        end

        def self.cleanup_test_views
          return unless Wdpa::Portal::Config::StagingConfig.test_mode?
          
          Rails.logger.info "Cleaning up dummy portal_standard_* tables..."
          
          tables = Wdpa::Portal::Config::StagingConfig.portal_views
          tables.each do |table_name|
            if table_exists?(table_name)
              ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{table_name}")
              Rails.logger.info "Dropped table: #{table_name}"
            end
          end
        end

        private

        def self.create_dummy_sources_table
          # Drop existing view first to ensure clean schema
          ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{Wdpa::Portal::Config::StagingConfig.portal_view_for('sources')}")
          
          # Create a table with dummy source data that matches the expected schema
          # Each source has a unique metadataid that can be referenced by protected areas
          sql = <<~SQL
            CREATE TABLE #{Wdpa::Portal::Config::StagingConfig.portal_view_for('sources')} AS
            SELECT 
              generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count * 2}) as metadataid,
              'Test Source ' || generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count * 2}) as title,
              'Test Responsible Party ' || generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count * 2}) as responsible_party,
              'test' || generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count * 2}) || '@example.com' as responsible_email,
              (DATE '2020-01-01' + (floor(random() * 4) * INTERVAL '1 year'))::date as year,
              'en' as language,
              'UTF-8' as character_set,
              'WGS84' as reference_system,
              '1:1000000' as scale,
              'Test lineage for source ' || generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count * 2}) as lineage,
              'Test citation for source ' || generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count * 2}) as citation,
              'Test disclaimer for source ' || generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count * 2}) as disclaimer
          SQL
          
          ActiveRecord::Base.connection.execute(sql)
          
          # Verify the table was created
          unless table_exists?(Wdpa::Portal::Config::StagingConfig.portal_view_for('sources'))
            raise "Failed to create #{Wdpa::Portal::Config::StagingConfig.portal_view_for('sources')} table"
          end
          
          Rails.logger.info "Created dummy #{Wdpa::Portal::Config::StagingConfig.portal_view_for('sources')} table with #{Wdpa::Portal::Config::StagingConfig.dummy_data_count * 2} records"
        end

        def self.create_dummy_polygons_table
          # Drop existing view first to ensure clean schema
          ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{Wdpa::Portal::Config::StagingConfig.portal_view_for('polygons')}")
          
          # Create a table with dummy polygon data that maps to protected areas
          # Use simple, valid geometries to avoid PostGIS errors
          # Each polygon references a source via metadataid
          sql = <<~SQL
            CREATE TABLE #{Wdpa::Portal::Config::StagingConfig.portal_view_for('polygons')} AS
            SELECT 
              generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count}) as wdpaid,
              generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count}) as wdpa_pid,
              'Test Protected Area ' || generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count}) as name,
              'Original Test Name ' || generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count}) as orig_name,
              (random() * 1000 + 100)::numeric(10,2) as rep_m_area,
              (random() * 1000 + 100)::numeric(10,2) as rep_area,
              (random() * 1000 + 100)::numeric(10,2) as gis_m_area,
              (random() * 1000 + 100)::numeric(10,2) as gis_area,
              (ARRAY['GBR', 'USA', 'CAN', 'AUS', 'BRA', 'KEN', 'TZA', 'ZAF', 'IND', 'CHN'])[floor(random() * 10 + 1)] as iso3,
              'Designated' as status,
              (2015 + floor(random() * 8))::integer as status_yr,
              (ARRAY['Ia', 'Ib', 'II', 'III', 'IV', 'V', 'VI', 'Not Reported'])[floor(random() * 8 + 1)] as iucn_cat,
              (ARRAY['Government', 'Joint', 'Private', 'Communal', 'Not Reported'])[floor(random() * 5 + 1)] as gov_type,
              'Test Management Authority ' || generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count}) as mang_auth,
              (ARRAY['Yes', 'No', 'Not Reported'])[floor(random() * 3 + 1)] as mang_plan,
              (ARRAY['Yes', 'No', 'Not Reported'])[floor(random() * 3 + 1)] as int_crit,
              (ARRAY['Marine', 'Terrestrial', 'Both', 'Not Reported'])[floor(random() * 4 + 1)] as marine,
              (ARRAY['National', 'Regional', 'International', 'Not Reported'])[floor(random() * 4 + 1)] as desig_eng,
              (ARRAY['National', 'Regional', 'International', 'Not Reported'])[floor(random() * 4 + 1)] as desig_type,
              (ARRAY['Yes', 'No', 'Not Reported'])[floor(random() * 3 + 1)] as no_take,
              (random() * 100 + 10)::numeric(10,2) as no_take_area,
              ST_GeomFromText('POLYGON((' || 
                (generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count}) * 0.1)::numeric(10,6) || ' ' || 
                (generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count}) * 0.1)::numeric(10,6) || ', ' ||
                ((generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count}) * 0.1 + 0.1)::numeric(10,6)) || ' ' || 
                (generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count}) * 0.1)::numeric(10,6) || ', ' ||
                ((generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count}) * 0.1 + 0.1)::numeric(10,6)) || ' ' || 
                ((generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count}) * 0.1 + 0.1)::numeric(10,6)) || ', ' ||
                (generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count}) * 0.1)::numeric(10,6) || ' ' || 
                ((generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count}) * 0.1 + 0.1)::numeric(10,6)) || ', ' ||
                (generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count}) * 0.1)::numeric(10,6) || ' ' || 
                (generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count}) * 0.1)::numeric(10,6) || '))') as wkb_geometry,
              true as is_polygon,
              generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count}) as metadataid
          SQL
          
          ActiveRecord::Base.connection.execute(sql)
          
          # Verify the table was created
          unless table_exists?(Wdpa::Portal::Config::StagingConfig.portal_view_for('polygons'))
            raise "Failed to create #{Wdpa::Portal::Config::StagingConfig.portal_view_for('polygons')} table"
          end
          
          Rails.logger.info "Created dummy #{Wdpa::Portal::Config::StagingConfig.portal_view_for('polygons')} table with #{Wdpa::Portal::Config::StagingConfig.dummy_data_count} records"
        end

        def self.create_dummy_points_table
          # Drop existing view first to ensure clean schema
          ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{Wdpa::Portal::Config::StagingConfig.portal_view_for('points')}")
          
          # Create a table with dummy point data that maps to protected areas
          # Use simple, valid point geometries
          # Each point references a source via metadataid
          sql = <<~SQL
            CREATE TABLE #{Wdpa::Portal::Config::StagingConfig.portal_view_for('points')} AS
            SELECT 
              generate_series(#{Wdpa::Portal::Config::StagingConfig.dummy_data_count + 1}, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count * 2}) as wdpaid,
              generate_series(#{Wdpa::Portal::Config::StagingConfig.dummy_data_count + 1}, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count * 2}) as wdpa_pid,
              'Test Point Area ' || generate_series(#{Wdpa::Portal::Config::StagingConfig.dummy_data_count + 1}, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count * 2}) as name,
              'Original Test Point Name ' || generate_series(#{Wdpa::Portal::Config::StagingConfig.dummy_data_count + 1}, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count * 2}) as orig_name,
              (random() * 1000 + 100)::numeric(10,2) as rep_m_area,
              (random() * 1000 + 100)::numeric(10,2) as rep_area,
              (random() * 1000 + 100)::numeric(10,2) as gis_m_area,
              (random() * 1000 + 100)::numeric(10,2) as gis_area,
              (ARRAY['USA', 'CAN', 'MEX', 'BRA', 'ARG', 'CHL', 'PER', 'COL', 'VEN', 'ECU'])[floor(random() * 10 + 1)] as iso3,
              'Designated' as status,
              (2016 + floor(random() * 8))::integer as status_yr,
              (ARRAY['Ia', 'Ib', 'II', 'III', 'IV', 'V', 'VI', 'Not Reported'])[floor(random() * 8 + 1)] as iucn_cat,
              (ARRAY['Government', 'Joint', 'Private', 'Communal', 'Not Reported'])[floor(random() * 5 + 1)] as gov_type,
              'Test Point Management Authority ' || generate_series(#{Wdpa::Portal::Config::StagingConfig.dummy_data_count + 1}, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count * 2}) as mang_auth,
              (ARRAY['Yes', 'No', 'Not Reported'])[floor(random() * 3 + 1)] as mang_plan,
              (ARRAY['Yes', 'No', 'Not Reported'])[floor(random() * 3 + 1)] as int_crit,
              (ARRAY['Marine', 'Terrestrial', 'Both', 'Not Reported'])[floor(random() * 4 + 1)] as marine,
              (ARRAY['State', 'Federal', 'Local', 'Not Reported'])[floor(random() * 4 + 1)] as desig_eng,
              (ARRAY['State', 'Federal', 'Local', 'Not Reported'])[floor(random() * 4 + 1)] as desig_type,
              (ARRAY['Yes', 'No', 'Not Reported'])[floor(random() * 3 + 1)] as no_take,
              (random() * 100 + 10)::numeric(10,2) as no_take_area,
              ST_GeomFromText('POINT(' || 
                ((generate_series(#{Wdpa::Portal::Config::StagingConfig.dummy_data_count + 1}, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count * 2}) * 0.1 - 90)::numeric(10,6)) || ' ' || 
                ((generate_series(#{Wdpa::Portal::Config::StagingConfig.dummy_data_count + 1}, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count * 2}) * 0.1 - 180)::numeric(10,6)) || ')') as wkb_geometry,
              false as is_polygon,
              generate_series(#{Wdpa::Portal::Config::StagingConfig.dummy_data_count + 1}, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count * 2}) as metadataid
          SQL
          
          ActiveRecord::Base.connection.execute(sql)
          
          # Verify the table was created
          unless table_exists?(Wdpa::Portal::Config::StagingConfig.portal_view_for('points'))
            raise "Failed to create #{Wdpa::Portal::Config::StagingConfig.portal_view_for('points')} table"
          end
          
          Rails.logger.info "Created dummy #{Wdpa::Portal::Config::StagingConfig.portal_view_for('points')} table with #{Wdpa::Portal::Config::StagingConfig.dummy_data_count} records"
        end

        def self.verify_tables_created
          required_tables = Wdpa::Portal::Config::StagingConfig.portal_views
          
          missing_tables = required_tables.select { |table_name| !table_exists?(table_name) }
          
          if missing_tables.any?
            Rails.logger.error "Failed to create the following tables: #{missing_tables.join(', ')}"
            raise "Failed to create dummy portal_standard_* tables: #{missing_tables.join(', ')}"
          end
          
          Rails.logger.info "All required dummy tables verified successfully"
        end

        def self.table_exists?(table_name)
          # Check if table exists using ActiveRecord
          ActiveRecord::Base.connection.table_exists?(table_name)
        end
      end
    end
  end
end
