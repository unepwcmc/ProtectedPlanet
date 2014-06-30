class Download::Kml < Download::Generator
  private

  def export
    export_from_postgres :kml
  end

  def path
    "#{path_without_extension}.kml"
  end
end
