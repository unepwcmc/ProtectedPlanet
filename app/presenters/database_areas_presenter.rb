class DatabaseAreasPresenter
  include Concerns::AreasCards

  def initialize(cms_site)
    @cms_site = cms_site
  end

  def database_areas
    database_page = @cms_site.pages.find_by_slug('databases')

    {
      title: database_page.label,
      cards: cards(database_page)
    }
  end
end