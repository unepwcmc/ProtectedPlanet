# frozen_string_literal: true

namespace :pp do
  namespace :test do
    # Regenerates test/support/portal_fdw/schema.sql from a database that has the
    # REAL portal_fdw foreign schema (a dev database set up per
    # docs/fdw_setup/local.md). Run it when the Data Management Portal schema
    # changes, then re-run the two release integration tests.
    #
    # Only the schema is regenerated. test/support/portal_fdw/seed.sql is written
    # by hand — its header explains why each row is needed — and may need a new
    # column filled if the portal adds a NOT NULL one.
    desc 'Regenerate the local portal_fdw test schema from a database with the real foreign schema'
    task regenerate_portal_fdw_schema: :environment do
      db = ActiveRecord::Base.connection_db_config.configuration_hash
      env = { 'PGPASSWORD' => db[:password].to_s }
      cmd = ['pg_dump', '--schema-only', '-n', 'portal_fdw',
             '-h', db[:host].to_s, '-p', db[:port].to_s, '-U', db[:username].to_s, db[:database].to_s]

      raw = IO.popen(env, cmd, err: %i[child out], &:read)
      abort "pg_dump failed:\n#{raw}" unless $?.success?
      abort 'No CREATE FOREIGN TABLE found — is portal_fdw a real foreign schema in this database?' unless raw.include?('CREATE FOREIGN TABLE')

      statements = raw.split(/;\s*\n/).map { |s| s.lines.reject { |l| l.start_with?('--') }.join.strip }.reject(&:empty?)

      out = statements.filter_map do |st|
        if st.start_with?('CREATE SCHEMA')
          'CREATE SCHEMA IF NOT EXISTS portal_fdw'
        elsif st.start_with?('CREATE FOREIGN TABLE')
          st.sub(/\ACREATE FOREIGN TABLE/, 'CREATE TABLE IF NOT EXISTS')
            .sub(/\)\s*SERVER\s+\w+\s+OPTIONS\s*\(.*\)\s*\z/m, ')')
        end
        # Everything else — ALTER FOREIGN TABLE column OPTIONS and OWNER, ALTER
        # SCHEMA OWNER, default privileges, SET — only means something with a
        # foreign server, so it is dropped.
      end

      leftover = out.grep(/SERVER|OPTIONS/)
      abort "Conversion left FDW clauses behind:\n#{leftover.first(3).join("\n")}" if leftover.any?

      path = Rails.root.join('test/support/portal_fdw/schema.sql')
      header = File.read(path)[/\A(?:--.*\n|\n)+/]
      File.write(path, header + out.join(";\n\n") + ";\n")

      puts "Wrote #{out.count { |s| s.start_with?('CREATE TABLE') }} tables to #{path.relative_path_from(Rails.root)}"
    end
  end
end
