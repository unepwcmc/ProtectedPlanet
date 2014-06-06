class Wdpa::ProtectedAreaImporter::GeometryImporter
  DB = ActiveRecord::Base.connection

  def self.import wdpa_release
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

  private

  def self.standard_geometry_attributes
    standard_attributes = Wdpa::DataStandard.standard_attributes

    standard_attributes.select do |key, hash|
      standard_attributes[key][:type] == :geometry
    end
  end
end
