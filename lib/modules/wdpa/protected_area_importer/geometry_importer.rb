class Wdpa::ProtectedAreaImporter::GeometryImporter
  DB = ActiveRecord::Base.connection

  def self.import wdpa_release
    standard_geometry_attributes = Wdpa::DataStandard.standard_geometry_attributes

    wdpa_release.geometry_tables.each do |table_name|
      standard_geometry_attributes.each do |attribute, value|
        query = """
          UPDATE protected_areas pa
          SET #{value[:name]} = import.#{attribute}
          FROM #{table_name} import
          WHERE pa.wdpa_id = import.wdpaid;
        """.squish

        DB.execute(query)
      end
    end

    true
  rescue
    return false
  end
end
