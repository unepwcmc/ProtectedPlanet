class ThematicAreasPresenter
  include Concerns::AreasCards

  def initialize(cms_site)
    @cms_site = cms_site
  end

  def thematic_areas
    area_payload('thematic-areas')
  end
end