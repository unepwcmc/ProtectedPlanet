class Download::Generators::Csv < Download::Generators::Base
  private

  def export
    export_from_postgres :csv
  end

  def path
    "#{path_without_extension}.csv"
  end
end
