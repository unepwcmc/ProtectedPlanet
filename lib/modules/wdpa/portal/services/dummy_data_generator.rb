module Wdpa
  module Portal
    module Services
      class DummyDataGenerator
        def self.generate_test_views
          Rails.logger.info 'Generating dummy portal_standard_* tables for testing...'

          create_dummy_sources_table

          create_dummy_polygons_table

          create_dummy_points_table

          verify_tables_created

          Rails.logger.info 'Dummy portal_standard_* tables created successfully'
        end

        def self.cleanup_test_views
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

          # Specific WDPA IDs requested by user (removing duplicates)
          specific_wdpa_ids = [17_231, 902_497, 555_558_374, 303_317, 309_970, 354_414, 32_674, 17_709, 18_807, 10_110, 306_777,
            792, 4106, 303_067, 345_942, 306_779, 306_780, 555_526_767, 303_072, 18_805, 4044, 62_735, 3014, 143, 7523, 555_526_045, 555_539_517, 303_038, 555_577_562, 303_320, 555_547_502, 20_299, 7878, 62_990, 168_201, 10_279, 256, 95_349, 30_697, 555_624_257, 61_611, 68_175, 555_526_032, 365_025, 659, 17_744, 64_511, 12_223, 7873, 10_754, 718, 63_642, 147_297, 555_599_909, 61_498, 330_608, 322, 67_860, 15_089, 147_302, 555_637_437, 388_659, 767, 1085, 819, 555_526_036, 311_888, 555_555_490, 95_996, 303_322, 64_513, 303_552, 17_360, 83_037, 555_555_513, 555_542_446, 108_125, 555_525_592, 555_544_085, 391_970, 20_186, 63_136, 26_654, 6271, 106_711, 18_998, 62_716, 3981, 15_260, 186, 555_577_562, 147_283, 1088, 769, 26_625, 555_555_517, 555_555_499, 83_268, 68_137, 555_526_606, 3451, 663, 5977, 61_595, 13_165, 662, 9782, 6307, 7461, 306_808, 9817, 768, 389_011, 349_467, 555_592_552, 303_066, 555_705_647, 555_697_546, 915, 721, 13_966, 345_888, 4114, 555_514_399, 555_705_603, 303_045, 902_487, 555_624_365, 555_548_807, 555_582_988, 555_525_849, 30_040, 36_534, 313_091, 17_748,
            # Additional IDs from PAME data
            555_622_076, 555_622_075, 555_622_070, 555_542_444, 555_622_067, 555_622_077, 555_622_072, 555_542_441, 555_558_373, 555_622_078, 555_542_442, 555_622_074, 555_622_073, 555_622_069, 555_622_084, 555_622_086,
            # Additional IDs from transboundary sites
            100_672, 100_673, 100_764, 100_798, 2904, 365_380, 555_605_094, 555_558_197, 142, 236, 2554, 61_610, 145_532, 328_846,
            # Additional IDs from DOPA4 and other sources
            1, 3, 4, 6, 7, 8, 10, 12, 15, 16, 17, 18, 19, 20, 21, 22, 24, 27, 30, 555_576_134].uniq

          # Create the table with a simpler approach
          table_name = Wdpa::Portal::Config::StagingConfig.portal_view_for('polygons')

          # First create the table structure with unique constraint
          create_table_sql = "CREATE TABLE #{table_name} (
            wdpaid integer,
            wdpa_pid text,
            name text,
            orig_name text,
            rep_m_area numeric(10,2),
            rep_area numeric(10,2),
            gis_m_area numeric(10,2),
            gis_area numeric(10,2),
            iso3 text,
            status text,
            status_yr integer,
            iucn_cat text,
            gov_type text,
            mang_auth text,
            mang_plan text,
            int_crit text,
            marine text,
            desig_eng text,
            desig_type text,
            no_take text,
            no_take_area numeric(10,2),
            wkb_geometry geometry,
            metadataid integer,
            UNIQUE(wdpaid, wdpa_pid)
          )"

          ActiveRecord::Base.connection.execute(create_table_sql)

          # Insert specific WDPA IDs with parcels (first 10 get 5 parcels each)
          multi_parcel_ids = specific_wdpa_ids.first(10)
          multi_parcel_ids.each do |wdpa_id|
            5.times do |parcel_num|
              insert_sql = "INSERT INTO #{table_name} VALUES (
                #{wdpa_id},
                '#{wdpa_id}_#{parcel_num + 1}',
                'Test Protected Area #{wdpa_id} - Parcel #{parcel_num + 1}',
                'Original Test Name #{wdpa_id} - Parcel #{parcel_num + 1}',
                #{rand(100..1100).round(2)},
                #{rand(100..1100).round(2)},
                #{rand(100..1100).round(2)},
                #{rand(100..1100).round(2)},
                '#{%w[GBR USA CAN AUS BRA KEN TZA ZAF IND CHN].sample}',
                'Designated',
                #{rand(2015..2022)},
                '#{['Ia', 'Ib', 'II', 'III', 'IV', 'V', 'VI', 'Not Reported'].sample}',
                '#{['Government', 'Joint', 'Private', 'Communal', 'Not Reported'].sample}',
                'Test Management Authority #{wdpa_id}',
                '#{['Yes', 'No', 'Not Reported'].sample}',
                '#{['Yes', 'No', 'Not Reported'].sample}',
                '#{['Marine', 'Terrestrial', 'Both', 'Not Reported'].sample}',
                '#{['National', 'Regional', 'International', 'Not Reported'].sample}',
                '#{['National', 'Regional', 'International', 'Not Reported'].sample}',
                '#{['Yes', 'No', 'Not Reported'].sample}',
                #{rand(10..110).round(2)},
                ST_GeomFromText('POLYGON((#{(wdpa_id * 0.1) + (parcel_num * 0.2)} #{(wdpa_id * 0.1) + (parcel_num * 0.2)}, #{(wdpa_id * 0.1) + (parcel_num * 0.2) + 0.1} #{(wdpa_id * 0.1) + (parcel_num * 0.2)}, #{(wdpa_id * 0.1) + (parcel_num * 0.2) + 0.1} #{(wdpa_id * 0.1) + (parcel_num * 0.2) + 0.1}, #{(wdpa_id * 0.1) + (parcel_num * 0.2)} #{(wdpa_id * 0.1) + (parcel_num * 0.2) + 0.1}, #{(wdpa_id * 0.1) + (parcel_num * 0.2)} #{(wdpa_id * 0.1) + (parcel_num * 0.2)}))'),
                #{rand(1..1000)}
              )"
              begin
                ActiveRecord::Base.connection.execute(insert_sql)
              rescue ActiveRecord::StatementInvalid => e
                raise e unless e.message.include?('duplicate key value')

                Rails.logger.warn "Skipping duplicate entry: wdpa_id=#{wdpa_id}, wdpa_pid=#{wdpa_id}_#{parcel_num + 1}"
              end
            end
          end

          # Insert remaining specific WDPA IDs as single parcels
          single_parcel_ids = specific_wdpa_ids[10..-1]
          single_parcel_ids.each do |wdpa_id|
            insert_sql = "INSERT INTO #{table_name} VALUES (
              #{wdpa_id},
              '#{wdpa_id}',
              'Test Protected Area #{wdpa_id}',
              'Original Test Name #{wdpa_id}',
              #{rand(100..1100).round(2)},
              #{rand(100..1100).round(2)},
              #{rand(100..1100).round(2)},
              #{rand(100..1100).round(2)},
              '#{%w[GBR USA CAN AUS BRA KEN TZA ZAF IND CHN].sample}',
              'Designated',
              #{rand(2015..2022)},
              '#{['Ia', 'Ib', 'II', 'III', 'IV', 'V', 'VI', 'Not Reported'].sample}',
              '#{['Government', 'Joint', 'Private', 'Communal', 'Not Reported'].sample}',
              'Test Management Authority #{wdpa_id}',
              '#{['Yes', 'No', 'Not Reported'].sample}',
              '#{['Yes', 'No', 'Not Reported'].sample}',
              '#{['Marine', 'Terrestrial', 'Both', 'Not Reported'].sample}',
              '#{['National', 'Regional', 'International', 'Not Reported'].sample}',
              '#{['National', 'Regional', 'International', 'Not Reported'].sample}',
              '#{['Yes', 'No', 'Not Reported'].sample}',
              #{rand(10..110).round(2)},
              ST_GeomFromText('POLYGON((#{wdpa_id * 0.1} #{wdpa_id * 0.1}, #{(wdpa_id * 0.1) + 0.1} #{wdpa_id * 0.1}, #{(wdpa_id * 0.1) + 0.1} #{(wdpa_id * 0.1) + 0.1}, #{wdpa_id * 0.1} #{(wdpa_id * 0.1) + 0.1}, #{wdpa_id * 0.1} #{wdpa_id * 0.1}))'),
              #{rand(1..1000)}
            )"
            begin
              ActiveRecord::Base.connection.execute(insert_sql)
            rescue ActiveRecord::StatementInvalid => e
              raise e unless e.message.include?('duplicate key value')

              Rails.logger.warn "Skipping duplicate entry: wdpa_id=#{wdpa_id}, wdpa_pid=#{wdpa_id}"
            end
          end

          # Insert random WDPA IDs as single parcels
          random_start = specific_wdpa_ids.max + 1
          random_end = random_start + Wdpa::Portal::Config::StagingConfig.dummy_data_count - 1
          (random_start..random_end).each do |wdpa_id|
            insert_sql = "INSERT INTO #{table_name} VALUES (
              #{wdpa_id},
              '#{wdpa_id}',
              'Test Protected Area #{wdpa_id}',
              'Original Test Name #{wdpa_id}',
              #{rand(100..1100).round(2)},
              #{rand(100..1100).round(2)},
              #{rand(100..1100).round(2)},
              #{rand(100..1100).round(2)},
              '#{%w[GBR USA CAN AUS BRA KEN TZA ZAF IND CHN].sample}',
              'Designated',
              #{rand(2015..2022)},
              '#{['Ia', 'Ib', 'II', 'III', 'IV', 'V', 'VI', 'Not Reported'].sample}',
              '#{['Government', 'Joint', 'Private', 'Communal', 'Not Reported'].sample}',
              'Test Management Authority #{wdpa_id}',
              '#{['Yes', 'No', 'Not Reported'].sample}',
              '#{['Yes', 'No', 'Not Reported'].sample}',
              '#{['Marine', 'Terrestrial', 'Both', 'Not Reported'].sample}',
              '#{['National', 'Regional', 'International', 'Not Reported'].sample}',
              '#{['National', 'Regional', 'International', 'Not Reported'].sample}',
              '#{['Yes', 'No', 'Not Reported'].sample}',
              #{rand(10..110).round(2)},
              ST_GeomFromText('POLYGON((#{wdpa_id * 0.1} #{wdpa_id * 0.1}, #{(wdpa_id * 0.1) + 0.1} #{wdpa_id * 0.1}, #{(wdpa_id * 0.1) + 0.1} #{(wdpa_id * 0.1) + 0.1}, #{wdpa_id * 0.1} #{(wdpa_id * 0.1) + 0.1}, #{wdpa_id * 0.1} #{wdpa_id * 0.1}))'),
              #{rand(1..1000)}
            )"
            begin
              ActiveRecord::Base.connection.execute(insert_sql)
            rescue ActiveRecord::StatementInvalid => e
              raise e unless e.message.include?('duplicate key value')

              Rails.logger.warn "Skipping duplicate entry: wdpa_id=#{wdpa_id}, wdpa_pid=#{wdpa_id}"
            end
          end

          # Verify the table was created
          raise "Failed to create #{table_name} table" unless table_exists?(table_name)

          # Count total records
          total_records = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{table_name}").to_i

          Rails.logger.info "Created dummy #{table_name} table with #{total_records} records"
          Rails.logger.info "Generated #{specific_wdpa_ids.length} specific WDPA IDs and #{Wdpa::Portal::Config::StagingConfig.dummy_data_count} random ones"
          Rails.logger.info 'Multi-parcel protected areas created: first 10 specific WDPA IDs (5 parcels each) - format like 17231_1, 17231_2, etc.'
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
