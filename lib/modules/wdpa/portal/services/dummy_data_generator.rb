module Wdpa
  module Portal
    module Services
      class DummyDataGenerator
        def self.generate_test_views
          return unless Wdpa::Portal::Config::StagingConfig.test_mode?

          Rails.logger.info 'Generating dummy portal_standard_* tables for testing...'

          create_dummy_sources_table

          create_dummy_polygons_table

          create_dummy_points_table

          verify_tables_created

          Rails.logger.info 'Dummy portal_standard_* tables created successfully'
        end

        def self.cleanup_test_views
          return unless Wdpa::Portal::Config::StagingConfig.test_mode?

          Rails.logger.info 'Cleaning up dummy portal_standard_* tables...'

          tables = Wdpa::Portal::Config::StagingConfig.portal_views
          tables.each do |table_name|
            if table_exists?(table_name)
              ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{table_name}")
              Rails.logger.info "Dropped table: #{table_name}"
            end
          end
        end

        def self.create_dummy_sources_table
          # Drop existing view first to ensure clean schema
          ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{Wdpa::Portal::Config::StagingConfig.portal_view_for('sources')}")

          # Create a table with dummy source data that matches the expected schema
          # Each source has a unique metadataid that can be referenced by protected areas
          sql = <<~SQL
            CREATE TABLE #{Wdpa::Portal::Config::StagingConfig.portal_view_for('sources')} AS
            SELECT#{' '}
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

          # Create a table with dummy polygon data that includes multi-parcel protected areas
          # Generate data in format like: wdpa_id:111, wdpa_pid:111_1 and wdpa_id:1111, wdpa_pid:111_2
          sql = <<~SQL
            CREATE TABLE #{Wdpa::Portal::Config::StagingConfig.portal_view_for('polygons')} AS
            WITH base_data AS (
              SELECT#{' '}
                generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count}) as base_id,
                'Test Protected Area ' || generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count}) as base_name,
                'Original Test Name ' || generate_series(1, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count}) as base_orig_name,
                (random() * 1000 + 100)::numeric(10,2) as base_rep_m_area,
                (random() * 1000 + 100)::numeric(10,2) as base_rep_area,
                (random() * 1000 + 100)::numeric(10,2) as base_gis_m_area,
                (random() * 1000 + 100)::numeric(10,2) as base_gis_area,
                (ARRAY['GBR', 'USA', 'CAN', 'AUS', 'BRA', 'KEN', 'TZA', 'ZAF', 'IND', 'CHN'])[floor(random() * 10 + 1)] as base_iso3,
                (2015 + floor(random() * 8))::integer as base_status_yr,
                (ARRAY['Ia', 'Ib', 'II', 'III', 'IV', 'V', 'VI', 'Not Reported'])[floor(random() * 8 + 1)] as base_iucn_cat,
                (ARRAY['Government', 'Joint', 'Private', 'Communal', 'Not Reported'])[floor(random() * 5 + 1)] as base_gov_type,
                (ARRAY['Yes', 'No', 'Not Reported'])[floor(random() * 3 + 1)] as base_mang_plan,
                (ARRAY['Yes', 'No', 'Not Reported'])[floor(random() * 3 + 1)] as base_int_crit,
                (ARRAY['Marine', 'Terrestrial', 'Both', 'Not Reported'])[floor(random() * 4 + 1)] as base_marine,
                (ARRAY['National', 'Regional', 'International', 'Not Reported'])[floor(random() * 4 + 1)] as base_desig_eng,
                (ARRAY['National', 'Regional', 'International', 'Not Reported'])[floor(random() * 4 + 1)] as base_desig_type,
                (ARRAY['Yes', 'No', 'Not Reported'])[floor(random() * 3 + 1)] as base_no_take,
                (random() * 100 + 10)::numeric(10,2) as base_no_take_area,
                (random() * 1000 + 1)::integer as base_metadataid
            ),
            parcel_numbers AS (
              SELECT generate_series(1, 5) as parcel_num
            ),
            multi_parcel_data AS (
              SELECT#{' '}
                b.base_id as wdpaid,
                b.base_id::text || '_' || p.parcel_num as wdpa_pid,
                b.base_name || ' - Parcel ' || p.parcel_num as name,
                b.base_orig_name || ' - Parcel ' || p.parcel_num as orig_name,
                b.base_rep_m_area as rep_m_area,
                b.base_rep_area as rep_area,
                b.base_gis_m_area as gis_m_area,
                b.base_gis_area as gis_area,
                b.base_iso3 as iso3,
                'Designated' as status,
                b.base_status_yr as status_yr,
                b.base_iucn_cat as iucn_cat,
                b.base_gov_type as gov_type,
                'Test Management Authority ' || b.base_id as mang_auth,
                b.base_mang_plan as mang_plan,
                b.base_int_crit as int_crit,
                b.base_marine as marine,
                b.base_desig_eng as desig_eng,
                b.base_desig_type as desig_type,
                b.base_no_take as no_take,
                b.base_no_take_area as no_take_area,
                ST_GeomFromText('POLYGON((' ||#{' '}
                  (b.base_id * 0.1 + (p.parcel_num - 1) * 0.2)::numeric(10,6) || ' ' ||#{' '}
                  (b.base_id * 0.1 + (p.parcel_num - 1) * 0.2)::numeric(10,6) || ', ' ||
                  ((b.base_id * 0.1 + (p.parcel_num - 1) * 0.2 + 0.1)::numeric(10,6)) || ' ' ||#{' '}
                  (b.base_id * 0.1 + (p.parcel_num - 1) * 0.2)::numeric(10,6) || ', ' ||
                  ((b.base_id * 0.1 + (p.parcel_num - 1) * 0.2 + 0.1)::numeric(10,6)) || ' ' ||#{' '}
                  ((b.base_id * 0.1 + (p.parcel_num - 1) * 0.2 + 0.1)::numeric(10,6)) || ', ' ||
                  (b.base_id * 0.1 + (p.parcel_num - 1) * 0.2)::numeric(10,6) || ' ' ||#{' '}
                  ((b.base_id * 0.1 + (p.parcel_num - 1) * 0.2 + 0.1)::numeric(10,6)) || ', ' ||
                  (b.base_id * 0.1 + (p.parcel_num - 1) * 0.2)::numeric(10,6) || ' ' ||#{' '}
                  (b.base_id * 0.1 + (p.parcel_num - 1) * 0.2)::numeric(10,6) || '))') as wkb_geometry,
                b.base_metadataid as metadataid
              FROM base_data b
              CROSS JOIN parcel_numbers p
              WHERE b.base_id IN (1, 2, 3, 4, 5)  -- Multi-parcel areas (using first 5 IDs for testing)
            ),
            single_parcel_data AS (
              SELECT#{' '}
                base_id as wdpaid,
                base_id::text as wdpa_pid,
                base_name as name,
                base_orig_name as orig_name,
                base_rep_m_area,
                base_rep_area,
                base_gis_m_area,
                base_gis_area,
                base_iso3,
                'Designated' as status,
                base_status_yr,
                base_iucn_cat,
                base_gov_type,
                'Test Management Authority ' || base_id as mang_auth,
                base_mang_plan,
                base_int_crit,
                base_marine,
                base_desig_eng,
                base_desig_type,
                base_no_take,
                base_no_take_area,
                ST_GeomFromText('POLYGON((' ||#{' '}
                  (base_id * 0.1)::numeric(10,6) || ' ' ||#{' '}
                  (base_id * 0.1)::numeric(10,6) || ', ' ||
                  ((base_id * 0.1 + 0.1)::numeric(10,6)) || ' ' ||#{' '}
                  (base_id * 0.1)::numeric(10,6) || ', ' ||
                  ((base_id * 0.1 + 0.1)::numeric(10,6)) || ' ' ||#{' '}
                  ((base_id * 0.1 + 0.1)::numeric(10,6)) || ', ' ||
                  (base_id * 0.1)::numeric(10,6) || ' ' ||#{' '}
                  ((base_id * 0.1 + 0.1)::numeric(10,6)) || ', ' ||
                  (base_id * 0.1)::numeric(10,6) || ' ' ||#{' '}
                  (base_id * 0.1)::numeric(10,6) || '))') as wkb_geometry,
                base_metadataid as metadataid
              FROM base_data
              WHERE base_id NOT IN (1, 2, 3, 4, 5)  -- Single-parcel areas (all other IDs)
            )
            SELECT * FROM multi_parcel_data
            UNION ALL
            SELECT * FROM single_parcel_data
          SQL

          ActiveRecord::Base.connection.execute(sql)

          # Verify the table was created
          unless table_exists?(Wdpa::Portal::Config::StagingConfig.portal_view_for('polygons'))
            raise "Failed to create #{Wdpa::Portal::Config::StagingConfig.portal_view_for('polygons')} table"
          end

          # Count total records
          total_records = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{Wdpa::Portal::Config::StagingConfig.portal_view_for('polygons')}").to_i

          Rails.logger.info "Created dummy #{Wdpa::Portal::Config::StagingConfig.portal_view_for('polygons')} table with #{total_records} records"
          Rails.logger.info 'Multi-parcel protected areas created: wdpa_id 1-5 (5 parcels each) - format like 1_1, 1_2, etc.'
        end

        def self.create_dummy_points_table
          # Drop existing view first to ensure clean schema
          ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{Wdpa::Portal::Config::StagingConfig.portal_view_for('points')}")

          # Create a table with dummy point data that maps to protected areas
          # Use simple, valid point geometries
          # Each point references a source via metadataid
          sql = <<~SQL
            CREATE TABLE #{Wdpa::Portal::Config::StagingConfig.portal_view_for('points')} AS
            SELECT#{' '}
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
              ST_GeomFromText('POINT(' ||#{' '}
                ((generate_series(#{Wdpa::Portal::Config::StagingConfig.dummy_data_count + 1}, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count * 2}) * 0.1 - 90)::numeric(10,6)) || ' ' ||#{' '}
                ((generate_series(#{Wdpa::Portal::Config::StagingConfig.dummy_data_count + 1}, #{Wdpa::Portal::Config::StagingConfig.dummy_data_count * 2}) * 0.1 - 180)::numeric(10,6)) || ')') as wkb_geometry,
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

          Rails.logger.info 'All required dummy tables verified successfully'
        end

        def self.table_exists?(table_name)
          # Check if table exists using ActiveRecord
          ActiveRecord::Base.connection.table_exists?(table_name)
        end
      end
    end
  end
end
