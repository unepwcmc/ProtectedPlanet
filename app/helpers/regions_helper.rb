module RegionsHelper
  def countries_and_territories
    @region.iso == "EU" ? @region.countries : @region.countries_and_territories
  end
end
