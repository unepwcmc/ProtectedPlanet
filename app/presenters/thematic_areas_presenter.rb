class ThematicAreasPresenter
  include Concerns::AreasCards

  def initialize(cms_site)
    @cms_site = cms_site
  end

  def thematic_areas
    thematic_page = @cms_site.pages.find_by_slug('thematic-areas')

    {
      title: thematic_page.label,
      cards: cards(thematic_page)
    }
  end
end