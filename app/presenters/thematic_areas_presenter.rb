class ThematicAreasPresenter
  include Concerns::AreasCards

  def initialize(cms_site)
    @cms_site = cms_site
  end

  def thematic_areas
    area_payload(PageSlugs::THEMATIC_AREAS)
  end
end