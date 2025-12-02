class Ogr::Postgres
  class ExportError < StandardError; end;

  WRONG_ARGUMENTS_MSG = 'Given new table name, but no original table name'
  DRIVERS = {
    shapefile: 'ESRI Shapefile',
    csv:       'CSV',
    gdb:       'FileGDB'
  }

  TEMPLATE_DIRECTORY = File.join(File.dirname(__FILE__), 'command_templates')
  TEMPLATES = {
    import:     File.read(File.join(TEMPLATE_DIRECTORY, 'postgres_import.erb')),
    export:     File.read(File.join(TEMPLATE_DIRECTORY, 'postgres_export.erb')),
    gdb_export: File.read(File.join(TEMPLATE_DIRECTORY, 'postgres_gdb_export.erb'))
  }

  def self.import file_path, original_table_name=nil, table_name=nil
    raise ArgumentError, WRONG_ARGUMENTS_MSG if table_name && !original_table_name
    system ogr_command(TEMPLATES[:import], binding)
  end

  def self.export file_type, file_name, query, geom_type='polygon'
    template = file_type == :gdb ? TEMPLATES[:gdb_export] : TEMPLATES[:export]
    # Used for adding the -update flag so to add different layers (poly point source)
    # into the same .gdb file
    needs_updating = File.exist?(file_name)
    # The name of the feature, e.g. WDPA_poly_MmmYYYY, WDPA_point_MmmYYYY
    feature_name = get_feature_name(file_name, geom_type)
    system ogr_command(template, binding)
  end

  private

  def self.db_config
    ActiveRecord::Base.connection_config
  end

  def self.ogr_command template, context
    compiled_template = ERB.new(template).result context
    compiled_template.squish
  end

  # The filename convention should be as follows:
  #
  # WDPA_MmmYYYY_Public if full WDPA (and only WDPA areas) download
  # WDOECM_MmmYYYY_Public if full WDOECM (and only WDOECM areas) download
  # WDPA_WDOECM_MmmYYYY_Public in all other scenarios.
  #
  # The GDB features naming convention follows the above with regards WDPA and WDOECM
  # but with a minor amendment described as follows:
  #
  # WDPA_WDOECM_poly_MmmYYYY if polygon feature
  # WDPA_WDOECM_point_MmmYYY if point feature
  #
  # So, given the original download filename,
  # the WDPA_WDOECM bit depends on what the areas are about, e.g. only WDPA,
  # only WDOECM or both. The 'Public' bit is removed and the date
  # and the geometry type are swapped.
  FEATURE_TYPES = {
    'polygon' => 'poly',
    'point' => 'point',
    # .gdb related types
    'multipolygon' => 'poly',
    'multipoint' => 'point',
    'source' => 'source'
  }.freeze
  def self.get_feature_name(filename, geom_type)
    # Remove any possible folder structure from the path and also the extension
    filename = filename.split('/').last[0..-5]
    # Split the filename. E.g. "WDPA_MmmYYY_Public" => ['WDPA', 'MmmYYY', 'Public']
    attrs = filename.split('_')
    # Given the original filename should also contains 'polygons' or 'points' at the end,
    # we remove this bit.
    attrs.pop if %w(multipolygons multipoints polygons points).include?(attrs[-1])
    # If the filename does not end with 'Public' it means there's also an identifier (e.g. an ISO or a SITE ID)
    # So the original filename would have been something like WDPA_MmmYYY_Public_identifier
    identifier = attrs.pop unless attrs[-1].downcase == 'public'
    # Replace 'Public' with the geometry type formatted correctly, e.g. => ['WDPA', 'MmmYYY', 'poly']
    attrs[-1] = FEATURE_TYPES[geom_type]
    # Swap date and geometry type, e.g. => ['WDPA', 'poly', 'MmmYYY']
    attrs[-1], attrs[-2] = attrs[-2], attrs[-1]
    # Join and get the new filename, e.g. => 'WDPA_poly_MmmYYY'
    [attrs, identifier].flatten.compact.join('_')
  end
end
