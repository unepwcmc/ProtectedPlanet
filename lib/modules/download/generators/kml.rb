class Download::Generators::Kml < Download::Generators::Base
  TYPE = 'kml'

  private

  def export
    export_from_postgres :kml
  end

  def path
    "#{path_without_extension}.kml"
  end
end
