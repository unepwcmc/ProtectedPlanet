class Wdpa::ProtectedAreaImporter::GeometryImporter
  def self.import wdpa_release
    standard_geometry_attributes = Wdpa::DataStandard.standard_geometry_attributes

    wdpa_release.geometry_tables.each do |_, std_table_name|
      standard_geometry_attributes.each do |attribute, value|
        import_geometry(value[:name], attribute, std_table_name)
        import_coordinates(value[:name])
      end
    end

    return true
  rescue
    return false
  end

  private

  def self.import_geometry standardised_name, original_name, table
    db.execute("""
      UPDATE protected_areas pa
      SET #{standardised_name} = import.#{original_name}
      FROM #{table} import
      WHERE pa.wdpa_id = import.wdpaid;
    """.squish)
  end

  def self.import_coordinates standardised_name
    db.execute("""
      UPDATE protected_areas pa
      SET #{standardised_name}_longitude = ST_X(ST_Centroid(#{standardised_name})),
          #{standardised_name}_latitude = ST_Y(ST_Centroid(#{standardised_name}));
    """.squish)
  end

  def self.db
    ActiveRecord::Base.connection
  end
end
