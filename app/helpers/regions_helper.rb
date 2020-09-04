module RegionsHelper
  def countries_and_territories
    @region.iso == "EU" ? @region.countries : @region.countries_and_territories
  end

  def has_documents local_assigns
    (local_assigns.has_key? :documents) && (local_assigns[:documents].length > 0)
  end
end
