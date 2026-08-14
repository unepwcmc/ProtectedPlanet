# Rails 7.1 load_defaults sets add_autoload_paths_to_load_path=false, so lib/modules
# subdirs are no longer on $LOAD_PATH -- use require_relative.
require_relative 'data_standard/source'

class Wdpa::SourceImporter
  def self.import wdpa_release
    importer = self.new wdpa_release
    importer.import
  end

  def initialize wdpa_release
    @wdpa_release = wdpa_release
  end

  def import
    sources = @wdpa_release.sources.map(&:symbolize_keys)

    sources.each do |source_attributes|
      standardised_attributes = Wdpa::DataStandard::Source.attributes_from_standards_hash(
        source_attributes
      )

      source = Source.create(standardised_attributes)
      return false unless source
    end

    return true
  end
end
