module Wdpa::Portal::Importers::GeometryImporter
  def self.import
    # Import geometry for staging tables that have geometry columns
    # Only Staging::ProtectedArea and Staging::ProtectedAreaParcel need geometry import
    results = {}

    # Import geometry for protected areas
    results[:protected_areas] = import_geometry_for_table(Staging::ProtectedArea.table_name)

    # Import geometry for protected area parcels
    results[:protected_area_parcels] = import_geometry_for_table(Staging::ProtectedAreaParcel.table_name)

    # Combine results
    total_imported = results[:protected_areas][:imported_count] + results[:protected_area_parcels][:imported_count]
    all_errors = results[:protected_areas][:errors] + results[:protected_area_parcels][:errors]

    Rails.logger.info "Geometry import completed: #{total_imported} records updated"

    {
      success: all_errors.empty?,
      imported_count: total_imported,
      errors: all_errors,
      details: results
    }
  end

  def self.import_geometry_for_table(target_table)
    # Validate that target table exists and has records
    unless validate_target_table(target_table)
      return {
        imported_count: 0,
        errors: ["Target staging table #{target_table} does not exist or has no records"]
      }
    end

    imported_count = 0
    errors = []

    # Process polygons and points separately using centralized configuration
    Wdpa::Portal::Config::StagingConfig.portal_protected_area_views.each do |view|
      result = import_geometry_from_view(view, target_table)
      imported_count += result[:count]
      errors.concat(result[:errors])
    rescue StandardError => e
      errors << "Geometry import error for #{view} in #{target_table}: #{e.message}"
      Rails.logger.error "Geometry import failed for #{view} in #{target_table}: #{e.message}"
    end

    Rails.logger.info "#{target_table}: #{imported_count} records updated"
    { imported_count: imported_count, errors: errors }
  end

  def self.import_geometry_from_view(view, target_table)
    connection = ActiveRecord::Base.connection

    # Get geometry column name from target table
    geometry_column = get_geometry_column(target_table)
    return { count: 0, errors: ["No geometry column found in #{target_table}"] } unless geometry_column

    # Determine the correct matching logic based on target table
    matching_condition = get_matching_condition(target_table)

    # Use UPDATE with JOIN for efficient geometry copying
    update_query = <<~SQL
      UPDATE #{target_table}#{' '}
      SET #{geometry_column} = v.wkb_geometry
      FROM #{view} v
      WHERE #{matching_condition}
        AND v.wkb_geometry IS NOT NULL
    SQL

    Rails.logger.debug "Executing geometry update: #{update_query}"
    result = connection.execute(update_query)

    Rails.logger.info "#{target_table} from #{view}: #{result.cmd_tuples} records"
    { count: result.cmd_tuples, errors: [] }
  end

  def self.validate_target_table(target_table)
    connection = ActiveRecord::Base.connection

    # Check if table exists
    unless connection.table_exists?(target_table)
      Rails.logger.error "Target table #{target_table} does not exist"
      return false
    end

    # Check if table has records
    count = connection.execute("SELECT COUNT(*) FROM #{target_table}").first['count'].to_i
    if count == 0
      Rails.logger.error "Target table #{target_table} has no records"
      return false
    end

    Rails.logger.info "#{target_table}: #{count} records validated"
    true
  end

  def self.get_geometry_column(target_table)
    # Find geometry columns using ColumnMapper mapping
    # This ensures consistency with the portal attribute mapping
    geometry_columns = find_geometry_columns_from_mapping

    connection = ActiveRecord::Base.connection

    # Find the first geometry column that exists in the target table
    geometry_columns.find do |col_name|
      connection.column_exists?(target_table, col_name)
    end
  end

  def self.find_geometry_columns_from_mapping
    # Extract all geometry column names from ColumnMapper
    Wdpa::Portal::Utils::ColumnMapper::PORTAL_TO_PP_MAPPING
      .select { |_portal_key, mapping| mapping[:type] == :geometry }
      .map { |_portal_key, mapping| mapping[:name] }
  end

  def self.get_matching_condition(target_table)
    # Determine if this table has wdpa_pid column (parcels vs protected areas)
    # This dynamically determines the correct matching logic based on table structure
    connection = ActiveRecord::Base.connection
    has_wdpa_pid = connection.column_exists?(target_table, 'wdpa_pid')

    if has_wdpa_pid
      # For tables with wdpa_pid (parcels): match on both wdpa_id AND wdpa_pid to ensure correct parcel
      # Cast both sides to text to handle type differences between portal views and staging tables
      "#{target_table}.wdpa_id = v.wdpaid AND #{target_table}.wdpa_pid::text = v.wdpa_pid::text"
    else
      # For tables without wdpa_pid (protected areas): match only on wdpa_id (single record per wdpa_id)
      "#{target_table}.wdpa_id = v.wdpaid"
    end
  end
end
