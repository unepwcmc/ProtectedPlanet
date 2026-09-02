# frozen_string_literal: true

module Wdpa
  module Portal
    module Adapters
      # Shared batch reader for the portal staging materialised views.
      #
      # These views used to be paged with `LIMIT n OFFSET m` and no ORDER BY.
      # Postgres guarantees no stable row order between two such queries — and
      # synchronize_seqscans actively starts a large seq scan at a shared,
      # arbitrary position — so consecutive pages silently overlapped and
      # skipped rows. Every view paged here has a unique index on its key
      # columns, so we page by that key instead: deterministic, index-backed,
      # and constant cost per batch rather than OFFSET's rescan of everything
      # already read.
      module KeysetBatches
        private

        def each_keyset_batch(view:, key_columns:, batch_size:, exclude_columns: [])
          conn = ActiveRecord::Base.lease_connection
          use_checkpoints = Wdpa::Portal::ImportRuntimeConfig.checkpoints?
          remaining = Wdpa::Portal::ImportRuntimeConfig.sample_limit
          order = key_columns.map { |c| conn.quote_column_name(c) }.join(', ')
          select_list = select_list(conn, view, exclude_columns)

          cursor = use_checkpoints ? Wdpa::Portal::Checkpoint.get_cursor(view).presence : nil

          loop do
            limit = remaining ? [batch_size, remaining].min : batch_size
            break if limit <= 0

            query = +"SELECT #{select_list} FROM #{view}"
            query << " WHERE #{keyset_predicate(conn, key_columns, cursor)}" if cursor
            query << " ORDER BY #{order} LIMIT #{limit}"

            batch = conn.select_all(query).to_a
            break if batch.empty?

            yield batch

            cursor = key_columns.map { |c| batch.last[c] }
            remaining -= batch.size if remaining
            Wdpa::Portal::Checkpoint.set_cursor(view, cursor) if use_checkpoints
            break if batch.size < limit
          end
        end

        # Naming the columns instead of `SELECT *` is what keeps a batch small:
        # the geometry columns are megabytes per row on the polygon view and the
        # attribute import discards them anyway.
        def select_list(conn, view, exclude_columns)
          return '*' if exclude_columns.empty?

          excluded = exclude_columns.map { |c| c.to_s.downcase }
          wanted = view_columns(conn, view).reject { |c| excluded.include?(c.downcase) }
          if wanted.empty?
            Rails.logger.warn("⚠️ Could not list columns of #{view}, falling back to SELECT * (geometry will be fetched)")
            return '*'
          end

          wanted.map { |c| conn.quote_column_name(c) }.join(', ')
        end

        # Materialised views are absent from information_schema.columns, so read
        # the catalog directly.
        def view_columns(conn, view)
          conn.select_values(<<~SQL.squish)
            SELECT attname FROM pg_attribute
            WHERE attrelid = #{conn.quote(view)}::regclass
              AND attnum > 0 AND NOT attisdropped
            ORDER BY attnum
          SQL
        rescue StandardError => e
          Rails.logger.warn("⚠️ Could not read columns of #{view}: #{e.message}")
          []
        end

        # Row comparison: `(site_id, site_pid) > (12, '12_1')`, which the unique
        # index on those columns can serve directly.
        def keyset_predicate(conn, key_columns, cursor)
          cols = key_columns.map { |c| conn.quote_column_name(c) }.join(', ')
          vals = cursor.map { |v| conn.quote(v) }.join(', ')
          "(#{cols}) > (#{vals})"
        end
      end
    end
  end
end
