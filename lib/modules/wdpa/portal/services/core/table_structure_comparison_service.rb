# frozen_string_literal: true

module Wdpa
  module Portal
    module Services
      module Core
        class TableStructureComparisonService
        def self.compare_live_vs_staging_tables
          new.compare_all_tables
        end

        def self.compare_specific_tables(live_table, staging_table)
          new.compare_tables(live_table, staging_table)
        end

        def self.compare_live_vs_backup_tables
          new.compare_all_backup_tables
        end

        def self.compare_staging_vs_backup_tables
          new.compare_all_staging_vs_backup_tables
        end

        def self.compare_all_three_types
          new.compare_live_staging_backup_tables
        end

        def initialize
          @connection = ActiveRecord::Base.connection
          @differences = []
          @all_mismatches = []
        end

        def ensure_staging_tables_exist
          puts '🏗️  Ensuring all staging tables exist...'
          puts '=' * 50

          staging_config = Wdpa::Portal::Config::PortalImportConfig.staging_live_tables_hash
          created_count = 0

          staging_config.each do |live_table, staging_table|
            if @connection.table_exists?(staging_table)
              puts "✅ Staging table already exists: #{staging_table}"
            else
              puts "\n📋 Creating missing staging table: #{staging_table}"
              puts "   From live table: #{live_table}"

              begin
                create_missing_staging_table(live_table, staging_table)
                puts "✅ Successfully created: #{staging_table}"
                created_count += 1
              rescue StandardError => e
                puts "❌ Failed to create #{staging_table}: #{e.message}"
              end
            end
          end

          puts "\n" + ('=' * 50)
          if created_count > 0
            puts "🎉 Created #{created_count} missing staging table(s)"
          else
            puts '✅ All staging tables already exist'
          end

          created_count
        end

        def compare_all_tables
          puts '🔍 Comparing Live vs Staging Table Structures'
          puts '=' * 60

          # Ensure all staging tables exist before comparison
          puts "\n🏗️  Ensuring staging tables exist..."
          ensure_staging_tables_exist
          puts ""

          staging_config = Wdpa::Portal::Config::PortalImportConfig.staging_live_tables_hash
          all_match = true
          @all_mismatches = []

          staging_config.each do |live_table, staging_table|
            puts "\n📋 Comparing: #{live_table} ↔ #{staging_table}"
            puts '-' * 40

            table_match = compare_tables(live_table, staging_table)
            all_match &&= table_match

            # Debug: Show current state
            puts "  Debug: #{live_table} vs #{staging_table} - table_match=#{table_match}, all_match=#{all_match}"

            if table_match
              puts '✅ Tables match perfectly'
            else
              puts '❌ Tables have differences'
              @all_mismatches << "#{live_table} ↔ #{staging_table}"
            end
          end

          puts "\n" + ('=' * 60)
          if all_match
            puts '🎉 All staging tables match their live counterparts!'
          else
            puts '⚠️  Some tables have structural differences'
            display_mismatch_summary
          end

          all_match
        end

        def compare_all_backup_tables
          puts '🔍 Comparing Live vs Backup Table Structures'
          puts '=' * 60

          live_tables = Wdpa::Portal::Config::PortalImportConfig.staging_live_tables_hash.keys
          all_match = true
          @all_mismatches = []

          live_tables.each do |live_table|
            backup_tables = find_backup_tables_for(live_table)

            if backup_tables.empty?
              puts "\n📋 No backup tables found for: #{live_table}"
              puts '⚠️  Skipping - no backup tables to compare'
              next
            end

            backup_tables.each do |backup_table|
              puts "\n📋 Comparing: #{live_table} ↔ #{backup_table}"
              puts '-' * 40

              table_match = compare_tables(live_table, backup_table)
              all_match &&= table_match

              if table_match
                puts '✅ Tables match perfectly'
              else
                puts '❌ Tables have differences'
                @all_mismatches << "#{live_table} ↔ #{backup_table}"
              end
            end
          end

          puts "\n" + ('=' * 60)
          if all_match
            puts '🎉 All backup tables match their live counterparts!'
          else
            puts '⚠️  Some backup tables have structural differences'
            display_mismatch_summary
          end

          all_match
        end

        def compare_all_staging_vs_backup_tables
          puts '🔍 Comparing Staging vs Backup Table Structures'
          puts '=' * 60

          # Ensure all staging tables exist before comparison
          puts "\n🏗️  Ensuring staging tables exist..."
          ensure_staging_tables_exist
          puts ""

          staging_config = Wdpa::Portal::Config::PortalImportConfig.staging_live_tables_hash
          all_match = true
          @all_mismatches = []

          staging_config.each do |live_table, staging_table|
            backup_tables = find_backup_tables_for(live_table)

            if backup_tables.empty?
              puts "\n📋 No backup tables found for: #{live_table}"
              puts '⚠️  Skipping - no backup tables to compare'
              next
            end

            backup_tables.each do |backup_table|
              puts "\n📋 Comparing: #{staging_table} ↔ #{backup_table}"
              puts '-' * 40

              table_match = compare_tables(staging_table, backup_table)
              all_match &&= table_match

              if table_match
                puts '✅ Tables match perfectly'
              else
                puts '❌ Tables have differences'
                @all_mismatches << "#{staging_table} ↔ #{backup_table}"
              end
            end
          end

          puts "\n" + ('=' * 60)
          if all_match
            puts '🎉 All staging tables match their backup counterparts!'
          else
            puts '⚠️  Some staging tables have structural differences from backups'
            display_mismatch_summary
          end

          all_match
        end

        def compare_live_staging_backup_tables
          puts '🔍 Comparing Live, Staging, and Backup Table Structures'
          puts '=' * 70

          # Ensure all staging tables exist before comparison
          puts "\n🏗️  Ensuring staging tables exist..."
          ensure_staging_tables_exist
          puts ""

          staging_config = Wdpa::Portal::Config::PortalImportConfig.staging_live_tables_hash
          all_match = true
          @all_mismatches = []

          staging_config.each do |live_table, staging_table|
            backup_tables = find_backup_tables_for(live_table)

            puts "\n📋 Table Group: #{live_table}"
            puts '=' * 50

            # Compare live vs staging
            puts "\n🔄 Live ↔ Staging"
            puts '-' * 20
            live_staging_match = compare_tables(live_table, staging_table)
            all_match &&= live_staging_match

            if live_staging_match
              puts '✅ Live ↔ Staging: Perfect match'
            else
              puts '❌ Live ↔ Staging: Has differences'
              @all_mismatches << "Live ↔ Staging: #{live_table} ↔ #{staging_table}"
            end

            # Compare live vs backup(s)
            if backup_tables.any?
              puts "\n🔄 Live ↔ Backup(s)"
              puts '-' * 20
              backup_tables.each do |backup_table|
                live_backup_match = compare_tables(live_table, backup_table)
                all_match &&= live_backup_match

                if live_backup_match
                  puts "✅ Live ↔ #{backup_table}: Perfect match"
                else
                  puts "❌ Live ↔ #{backup_table}: Has differences"
                  @all_mismatches << "Live ↔ Backup: #{live_table} ↔ #{backup_table}"
                end
              end

              # Compare staging vs backup(s)
              puts "\n🔄 Staging ↔ Backup(s)"
              puts '-' * 20
              backup_tables.each do |backup_table|
                staging_backup_match = compare_tables(staging_table, backup_table)
                all_match &&= staging_backup_match

                if staging_backup_match
                  puts "✅ Staging ↔ #{backup_table}: Perfect match"
                else
                  puts "❌ Staging ↔ #{backup_table}: Has differences"
                  @all_mismatches << "Staging ↔ Backup: #{staging_table} ↔ #{backup_table}"
                end
              end
            else
              puts "\n⚠️  No backup tables found for #{live_table}"
            end
          end

          puts "\n" + ('=' * 70)
          if all_match
            puts '🎉 All table structures match perfectly across live, staging, and backup!'
          else
            puts '⚠️  Some tables have structural differences across the different types'
            display_mismatch_summary
          end

          all_match
        end

        def compare_tables(live_table, staging_table)
          return false unless both_tables_exist?(live_table, staging_table)

          differences = []

          # Compare basic table info
          differences.concat(compare_table_info(live_table, staging_table))

          # Compare columns
          differences.concat(compare_columns(live_table, staging_table))

          # Compare indexes
          differences.concat(compare_indexes(live_table, staging_table))

          # Compare constraints
          differences.concat(compare_constraints(live_table, staging_table))

          # Compare sequences
          differences.concat(compare_sequences(live_table, staging_table))

          # Compare triggers
          differences.concat(compare_triggers(live_table, staging_table))

          if differences.any?
            puts "Found #{differences.length} difference(s):"
            differences.each_with_index do |diff, index|
              puts "  #{index + 1}. #{diff}"
            end
            return false
          end

          true
        end

        private

        def create_missing_staging_table(_live_table, staging_table)
          # Use the StagingTableManager to create the staging table
          Wdpa::Portal::Managers::StagingTableManager.create_staging_table(staging_table)

          # Add foreign keys if needed
          Wdpa::Portal::Managers::StagingTableManager.add_foreign_keys_to_staging_table(staging_table)
        end

        def find_backup_tables_for(live_table)
          # Find all backup tables for a given live table
          # Backup tables follow the pattern: bk{timestamp}_table_name
          backup_tables = []

          result = @connection.execute(<<~SQL)
            SELECT table_name#{' '}
            FROM information_schema.tables#{' '}
            WHERE table_name LIKE 'bk%_#{live_table}'
            AND table_schema = 'public'
            ORDER BY table_name
          SQL

          result.each do |row|
            backup_tables << row['table_name']
          end

          backup_tables
        end

        def both_tables_exist?(live_table, staging_table)
          live_exists = @connection.table_exists?(live_table)
          staging_exists = @connection.table_exists?(staging_table)

          unless live_exists
            puts "❌ Live table '#{live_table}' does not exist"
            return false
          end

          unless staging_exists
            puts "⚠️  Staging table '#{staging_table}' does not exist"
            puts "🏗️  Creating staging table '#{staging_table}' from live table '#{live_table}'..."

            begin
              create_missing_staging_table(live_table, staging_table)
              puts "✅ Successfully created staging table '#{staging_table}'"
            rescue StandardError => e
              puts "❌ Failed to create staging table '#{staging_table}': #{e.message}"
              return false
            end
          end

          true
        end

        def compare_table_info(live_table, staging_table)
          differences = []

          live_info = get_table_info(live_table)
          staging_info = get_table_info(staging_table)

          # Compare table owner
          if live_info[:owner] != staging_info[:owner]
            differences << "Owner: live=#{live_info[:owner]}, staging=#{staging_info[:owner]}"
          end

          # Compare table space
          if live_info[:tablespace] != staging_info[:tablespace]
            differences << "Tablespace: live=#{live_info[:tablespace]}, staging=#{staging_info[:tablespace]}"
          end

          # Compare table options
          if live_info[:options] != staging_info[:options]
            differences << "Table options: live=#{live_info[:options]}, staging=#{staging_info[:options]}"
          end

          differences
        end

        def get_table_info(table_name)
          result = @connection.execute(<<~SQL)
            SELECT#{' '}
              schemaname,
              tablename,
              tableowner,
              tablespace,
              hasindexes,
              hasrules,
              hastriggers,
              rowsecurity
            FROM pg_tables#{' '}
            WHERE tablename = '#{table_name}'
          SQL

          if result.any?
            row = result.first
            {
              schema: row['schemaname'],
              name: row['tablename'],
              owner: row['tableowner'],
              tablespace: row['tablespace'],
              has_indexes: row['hasindexes'],
              has_rules: row['hasrules'],
              has_triggers: row['hastriggers'],
              row_security: row['rowsecurity']
            }
          else
            {}
          end
        end

        def compare_columns(live_table, staging_table)
          differences = []

          live_columns = get_table_columns(live_table)
          staging_columns = get_table_columns(staging_table)

          # Check column count
          if live_columns.length != staging_columns.length
            differences << "Column count: live=#{live_columns.length}, staging=#{staging_columns.length}"
          end

          # Compare each column
          all_column_names = (live_columns.keys + staging_columns.keys).uniq
          all_column_names.each do |column_name|
            live_col = live_columns[column_name]
            staging_col = staging_columns[column_name]

            if live_col.nil?
              differences << "Column '#{column_name}' missing in live table"
            elsif staging_col.nil?
              differences << "Column '#{column_name}' missing in staging table"
            else
              column_diffs = compare_column_details(column_name, live_col, staging_col)
              differences.concat(column_diffs)
            end
          end

          differences
        end

        def get_table_columns(table_name)
          columns = {}

          result = @connection.execute(<<~SQL)
            SELECT#{' '}
              column_name,
              data_type,
              is_nullable,
              column_default,
              character_maximum_length,
              numeric_precision,
              numeric_scale,
              datetime_precision,
              udt_name
            FROM information_schema.columns#{' '}
            WHERE table_name = '#{table_name}'#{' '}
            ORDER BY ordinal_position
          SQL

          result.each do |row|
            columns[row['column_name']] = {
              name: row['column_name'],
              data_type: row['data_type'],
              is_nullable: row['is_nullable'],
              default: row['column_default'],
              max_length: row['character_maximum_length'],
              precision: row['numeric_precision'],
              scale: row['numeric_scale'],
              datetime_precision: row['datetime_precision'],
              udt_name: row['udt_name']
            }
          end

          columns
        end

        def compare_column_details(column_name, live_col, staging_col)
          differences = []

          # Compare data type
          if live_col[:data_type] != staging_col[:data_type]
            differences << "Column '#{column_name}' data_type: live=#{live_col[:data_type]}, staging=#{staging_col[:data_type]}"
          end

          # Compare nullable
          if live_col[:is_nullable] != staging_col[:is_nullable]
            differences << "Column '#{column_name}' nullable: live=#{live_col[:is_nullable]}, staging=#{staging_col[:is_nullable]}"
          end

          # Compare default value (but ignore sequence name differences)
          unless default_values_equivalent?(live_col[:default], staging_col[:default])
            differences << "Column '#{column_name}' default: live=#{live_col[:default]}, staging=#{staging_col[:default]}"
          end

          # Compare length constraints
          if live_col[:max_length] != staging_col[:max_length]
            differences << "Column '#{column_name}' max_length: live=#{live_col[:max_length]}, staging=#{staging_col[:max_length]}"
          end

          # Compare numeric precision
          if live_col[:precision] != staging_col[:precision]
            differences << "Column '#{column_name}' precision: live=#{live_col[:precision]}, staging=#{staging_col[:precision]}"
          end

          # Compare numeric scale
          if live_col[:scale] != staging_col[:scale]
            differences << "Column '#{column_name}' scale: live=#{live_col[:scale]}, staging=#{staging_col[:scale]}"
          end

          differences
        end

        def default_values_equivalent?(live_default, staging_default)
          # Compare default values, but consider sequence defaults as equivalent
          # even if they reference different sequence names

          return true if live_default == staging_default
          return false if live_default.nil? || staging_default.nil?

          # Check if both are sequence defaults (nextval calls)
          live_is_sequence = live_default.match?(/nextval\(/)
          staging_is_sequence = staging_default.match?(/nextval\(/)

          # If both are sequence defaults, they're equivalent
          return true if live_is_sequence && staging_is_sequence

          # Otherwise, they must be exactly equal
          live_default == staging_default
        end

        def compare_indexes(live_table, staging_table)
          differences = []

          live_indexes = get_table_indexes(live_table)
          staging_indexes = get_table_indexes(staging_table)

          # Skip count comparison - we only care about index structure/settings
          # Compare indexes by structure, not by name
          # Group indexes by their structural properties
          live_index_groups = group_indexes_by_structure(live_indexes)
          staging_index_groups = group_indexes_by_structure(staging_indexes)

          # Compare each structural group
          all_structures = (live_index_groups.keys + staging_index_groups.keys).uniq
          all_structures.each do |structure_key|
            live_group = live_index_groups[structure_key]
            staging_group = staging_index_groups[structure_key]

            if live_group.nil?
              differences << "Index structure missing in live table: #{structure_key}"
            elsif staging_group.nil?
              differences << "Index structure missing in staging table: #{structure_key}"
            end
            # NOTE: We intentionally skip count comparison within each structure group
            # as backup tables may have different numbers of indexes but same types
          end

          differences
        end

        def get_table_indexes(table_name)
          indexes = {}

          result = @connection.execute(<<~SQL)
            SELECT#{' '}
              i.indexname,
              i.indexdef,
              idx.indisunique,
              idx.indisprimary,
              idx.indisclustered,
              idx.indkey,
              idx.indoption
            FROM pg_indexes i
            JOIN pg_class c ON c.relname = i.indexname
            JOIN pg_index idx ON idx.indexrelid = c.oid
            WHERE i.tablename = '#{table_name}'
            ORDER BY i.indexname
          SQL

          result.each do |row|
            indexes[row['indexname']] = {
              name: row['indexname'],
              definition: row['indexdef'],
              unique: row['indisunique'],
              primary: row['indisprimary'],
              clustered: row['indisclustered'],
              key_columns: row['indkey'],
              options: row['indoption']
            }
          end

          indexes
        end

        def group_indexes_by_structure(indexes)
          groups = {}

          indexes.each do |index_name, index_data|
            # Create a structural key based on the index properties
            # This ignores the actual index name and focuses on structure
            structure_key = create_index_structure_key(index_data)

            groups[structure_key] ||= []
            groups[structure_key] << {
              name: index_name,
              data: index_data
            }
          end

          groups
        end

        def create_index_structure_key(index_data)
          # Create a key that represents the structural properties of an index
          # This should be the same for equivalent indexes regardless of name

          # Extract the actual column names from the index definition
          # This is more reliable than using indkey which is just numbers
          definition = index_data[:definition]

          # For primary keys, use a special marker
          return 'PRIMARY_KEY' if index_data[:primary]

          # For unique indexes, extract the unique constraint info
          if index_data[:unique]
            # Extract column names from the definition
            columns = extract_columns_from_index_definition(definition)
            return "UNIQUE_#{columns.sort.join('_')}"
          end

          # For regular indexes, extract column names
          columns = extract_columns_from_index_definition(definition)
          "INDEX_#{columns.sort.join('_')}"
        end

        def extract_columns_from_index_definition(definition)
          # Extract column names from PostgreSQL index definition
          # Example: "CREATE INDEX index_name ON table_name USING btree (column1, column2)"
          # We want to extract: ["column1", "column2"]

          # Find the part in parentheses
          match = definition.match(/\(([^)]+)\)/)
          return [] unless match

          # Split by comma and clean up
          match[1].split(',').map do |col|
            col.strip.gsub(/^"(.+)"$/, '\1') # Remove quotes if present
          end
        end

        def compare_index_details(index_name, live_idx, staging_idx)
          differences = []

          # Compare definition
          differences << "Index '#{index_name}' definition differs" if live_idx[:definition] != staging_idx[:definition]

          # Compare unique constraint
          if live_idx[:unique] != staging_idx[:unique]
            differences << "Index '#{index_name}' unique: live=#{live_idx[:unique]}, staging=#{staging_idx[:unique]}"
          end

          # Compare primary key
          if live_idx[:primary] != staging_idx[:primary]
            differences << "Index '#{index_name}' primary: live=#{live_idx[:primary]}, staging=#{staging_idx[:primary]}"
          end

          differences
        end

        def compare_constraints(live_table, staging_table)
          differences = []

          live_constraints = get_table_constraints(live_table)
          staging_constraints = get_table_constraints(staging_table)

          # Filter out auto-generated constraint names that are expected to be different
          live_filtered = filter_expected_constraint_differences(live_constraints, live_table)
          staging_filtered = filter_expected_constraint_differences(staging_constraints, staging_table)

          # Skip count comparison - we only care about constraint structure/settings
          # Compare constraints by structure, not by name
          live_groups = group_constraints_by_structure(live_filtered)
          staging_groups = group_constraints_by_structure(staging_filtered)

          # Compare each structural group
          all_structures = (live_groups.keys + staging_groups.keys).uniq
          all_structures.each do |structure_key|
            live_group = live_groups[structure_key]
            staging_group = staging_groups[structure_key]

            if live_group.nil?
              differences << "Constraint structure missing in live table: #{structure_key}"
            elsif staging_group.nil?
              differences << "Constraint structure missing in staging table: #{structure_key}"
            end
            # NOTE: We intentionally skip count comparison within each structure group
            # as backup tables may have different numbers of constraints but same types
          end

          differences
        end

        def get_table_constraints(table_name)
          constraints = {}

          result = @connection.execute(<<~SQL)
            SELECT#{' '}
              tc.constraint_name,
              tc.constraint_type,
              tc.is_deferrable,
              tc.initially_deferred,
              cc.check_clause
            FROM information_schema.table_constraints tc
            LEFT JOIN information_schema.check_constraints cc#{' '}
              ON tc.constraint_name = cc.constraint_name
            WHERE tc.table_name = '#{table_name}'
            ORDER BY tc.constraint_name
          SQL

          result.each do |row|
            constraints[row['constraint_name']] = {
              name: row['constraint_name'],
              type: row['constraint_type'],
              deferrable: row['is_deferrable'],
              initially_deferred: row['initially_deferred'],
              check_clause: row['check_clause']
            }
          end

          constraints
        end

        def filter_expected_constraint_differences(constraints, table_name)
          # Filter out auto-generated constraint names that are expected to be different
          # These are typically PostgreSQL auto-generated names like "2200_5754646_1_not_null"
          filtered = {}

          constraints.each do |constraint_name, constraint_data|
            # Skip auto-generated constraint names (they have numeric patterns)
            next if constraint_name.match?(/^\d+_\d+_\d+_/)

            # Skip table-specific primary key constraints (they have different names)
            next if constraint_name == "#{table_name}_pkey"

            filtered[constraint_name] = constraint_data
          end

          filtered
        end

        def group_constraints_by_structure(constraints)
          groups = {}

          constraints.each do |constraint_name, constraint_data|
            # Create a structural key based on the constraint properties
            structure_key = create_constraint_structure_key(constraint_data)

            groups[structure_key] ||= []
            groups[structure_key] << {
              name: constraint_name,
              data: constraint_data
            }
          end

          groups
        end

        def create_constraint_structure_key(constraint_data)
          # Create a key that represents the structural properties of a constraint
          case constraint_data[:type]
          when 'PRIMARY KEY'
            'PRIMARY_KEY'
          when 'UNIQUE'
            'UNIQUE_CONSTRAINT'
          when 'CHECK'
            "CHECK_#{constraint_data[:check_clause]&.hash || 'unknown'}"
          when 'FOREIGN KEY'
            'FOREIGN_KEY'
          else
            "#{constraint_data[:type]}_CONSTRAINT"
          end
        end

        def compare_constraint_details(constraint_name, live_constraint, staging_constraint)
          differences = []

          # Compare constraint type
          if live_constraint[:type] != staging_constraint[:type]
            differences << "Constraint '#{constraint_name}' type: live=#{live_constraint[:type]}, staging=#{staging_constraint[:type]}"
          end

          # Compare deferrable
          if live_constraint[:deferrable] != staging_constraint[:deferrable]
            differences << "Constraint '#{constraint_name}' deferrable: live=#{live_constraint[:deferrable]}, staging=#{staging_constraint[:deferrable]}"
          end

          # Compare check clause
          if live_constraint[:check_clause] != staging_constraint[:check_clause]
            differences << "Constraint '#{constraint_name}' check_clause differs"
          end

          differences
        end

        def compare_sequences(live_table, staging_table)
          differences = []

          live_sequences = get_table_sequences(live_table)
          staging_sequences = get_table_sequences(staging_table)

          # Filter out backup sequences and other non-essential sequences
          live_filtered = filter_expected_sequence_differences(live_sequences, live_table)
          staging_filtered = filter_expected_sequence_differences(staging_sequences, staging_table)

          # Skip count comparison - we only care about sequence structure/settings
          # Compare sequences by structure, not by name
          live_groups = group_sequences_by_structure(live_filtered)
          staging_groups = group_sequences_by_structure(staging_filtered)

          # Compare each structural group
          all_structures = (live_groups.keys + staging_groups.keys).uniq
          all_structures.each do |structure_key|
            live_group = live_groups[structure_key]
            staging_group = staging_groups[structure_key]

            if live_group.nil?
              differences << "Sequence structure missing in live table: #{structure_key}"
            elsif staging_group.nil?
              differences << "Sequence structure missing in staging table: #{structure_key}"
            end
            # NOTE: We intentionally skip count comparison within each structure group
            # as staging tables may have different numbers of sequences but same types
          end

          differences
        end

        def get_table_sequences(table_name)
          sequences = {}

          result = @connection.execute(<<~SQL)
            SELECT#{' '}
              s.sequence_name,
              s.data_type,
              s.start_value,
              s.minimum_value,
              s.maximum_value,
              s.increment,
              s.cycle_option
            FROM information_schema.sequences s
            WHERE s.sequence_name LIKE '%#{table_name}%'
            ORDER BY s.sequence_name
          SQL

          result.each do |row|
            sequences[row['sequence_name']] = {
              name: row['sequence_name'],
              data_type: row['data_type'],
              start_value: row['start_value'],
              min_value: row['minimum_value'],
              max_value: row['maximum_value'],
              increment: row['increment'],
              cycle: row['cycle_option']
            }
          end

          sequences
        end

        def filter_expected_sequence_differences(sequences, table_name)
          # Filter out backup sequences and other non-essential sequences
          filtered = {}

          sequences.each do |sequence_name, sequence_data|
            # Skip backup sequences (they have bk timestamp prefix patterns)
            next if sequence_name.match?(/^bk\d{10}_/)

            # Skip sequences that don't belong to this table
            next unless sequence_name.include?(table_name)

            # Skip sequences from other tables that might match the pattern
            # Only include sequences that are specifically for this table
            next unless sequence_name.match?(/^#{table_name}_\w+_seq$/) ||
                        sequence_name.match?(/^staging_#{table_name}_\w+_seq$/)

            filtered[sequence_name] = sequence_data
          end

          filtered
        end

        def group_sequences_by_structure(sequences)
          groups = {}

          sequences.each do |sequence_name, sequence_data|
            # Create a structural key based on the sequence properties
            structure_key = create_sequence_structure_key(sequence_data)

            groups[structure_key] ||= []
            groups[structure_key] << {
              name: sequence_name,
              data: sequence_data
            }
          end

          groups
        end

        def create_sequence_structure_key(sequence_data)
          # Create a key that represents the structural properties of a sequence
          # This ignores the actual sequence name and focuses on structure
          "#{sequence_data[:data_type]}_#{sequence_data[:increment]}_#{sequence_data[:cycle]}"
        end

        def compare_sequence_details(sequence_name, live_seq, staging_seq)
          differences = []

          # Compare data type
          if live_seq[:data_type] != staging_seq[:data_type]
            differences << "Sequence '#{sequence_name}' data_type: live=#{live_seq[:data_type]}, staging=#{staging_seq[:data_type]}"
          end

          # Compare start value
          if live_seq[:start_value] != staging_seq[:start_value]
            differences << "Sequence '#{sequence_name}' start_value: live=#{live_seq[:start_value]}, staging=#{staging_seq[:start_value]}"
          end

          # Compare increment
          if live_seq[:increment] != staging_seq[:increment]
            differences << "Sequence '#{sequence_name}' increment: live=#{live_seq[:increment]}, staging=#{staging_seq[:increment]}"
          end

          differences
        end

        def compare_triggers(live_table, staging_table)
          differences = []

          live_triggers = get_table_triggers(live_table)
          staging_triggers = get_table_triggers(staging_table)

          # Skip count comparison - we only care about trigger structure/settings
          # Compare each trigger
          all_trigger_names = (live_triggers.keys + staging_triggers.keys).uniq
          all_trigger_names.each do |trigger_name|
            live_trigger = live_triggers[trigger_name]
            staging_trigger = staging_triggers[trigger_name]

            if live_trigger.nil?
              differences << "Trigger '#{trigger_name}' missing in live table"
            elsif staging_trigger.nil?
              differences << "Trigger '#{trigger_name}' missing in staging table"
            else
              trigger_diffs = compare_trigger_details(trigger_name, live_trigger, staging_trigger)
              differences.concat(trigger_diffs)
            end
          end

          differences
        end

        def get_table_triggers(table_name)
          triggers = {}

          result = @connection.execute(<<~SQL)
            SELECT#{' '}
              t.trigger_name,
              t.event_manipulation,
              t.action_timing,
              t.action_statement,
              t.action_orientation
            FROM information_schema.triggers t
            WHERE t.event_object_table = '#{table_name}'
            ORDER BY t.trigger_name
          SQL

          result.each do |row|
            triggers[row['trigger_name']] = {
              name: row['trigger_name'],
              event: row['event_manipulation'],
              timing: row['action_timing'],
              statement: row['action_statement'],
              orientation: row['action_orientation']
            }
          end

          triggers
        end

        def compare_trigger_details(trigger_name, live_trigger, staging_trigger)
          differences = []

          # Compare event
          if live_trigger[:event] != staging_trigger[:event]
            differences << "Trigger '#{trigger_name}' event: live=#{live_trigger[:event]}, staging=#{staging_trigger[:event]}"
          end

          # Compare timing
          if live_trigger[:timing] != staging_trigger[:timing]
            differences << "Trigger '#{trigger_name}' timing: live=#{live_trigger[:timing]}, staging=#{staging_trigger[:timing]}"
          end

          # Compare statement
          if live_trigger[:statement] != staging_trigger[:statement]
            differences << "Trigger '#{trigger_name}' statement differs"
          end

          differences
        end

        def display_mismatch_summary
          return if @all_mismatches.empty?

          puts "\n" + ('=' * 60)
          puts '📊 MISMATCH SUMMARY'
          puts '=' * 60
          puts "Found #{@all_mismatches.length} table pair(s) with structural differences:"
          puts ''

          @all_mismatches.each_with_index do |mismatch, index|
            puts "  #{index + 1}. #{mismatch}"
          end

          puts ''
          puts '💡 Tip: Review the detailed differences above for each table pair'
          puts '   to understand what structural elements need attention.'
          puts '=' * 60
        end
      end
    end
  end
        endend
