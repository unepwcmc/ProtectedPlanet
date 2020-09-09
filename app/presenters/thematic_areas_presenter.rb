class ThematicAreasPresenter
  include ActionView::Helpers::NumberHelper

  def initialize(cms_site)
    @cms_site = cms_site
  end

  def thematic_areas
    thematic_page = @cms_site.pages.find_by_slug('thematic-areas')

    items = {
      "title": thematic_page.label,
      "cards": cards(thematic_page)
    }
  end

  private

  def cards(thematic_page)
    _cards = thematic_page.children.published
    _cards.map do |c|
      {
        obj: c,
        pas_no: pas_figure(c.label)
      }
    end
  end

  THEMATIC_AREAS = {
    marine: 'Marine Protected Areas',
    green_list: 'The IUCN Green List of Protected and Conserved Areas',
    wdpa: 'WDPA',
    oecm: 'OECMs',
    connectivity: 'Connectivity Conservation',
    pame: 'Protected Areas Management Effectiveness (PAME)',
    equity: 'Equity and protected areas',
    aichi11: 'Global Partnership on Aichi Target 11'
  }.freeze
  def pas_figure(label)
    pas = ProtectedArea
    pas = case label
    when theme(:marine)
      pas.where(marine: true)
    when theme(:green_list)
      pas.where.not(green_list_status_id: nil)
    when theme(:wdpa)
      pas.wdpas
    when theme(:oecm)
      pas.oecms
    when theme(:pame)
      pas.with_pame_evaluations
    else
      -1 #Not applicable - hide ribbon
    end

    pas.respond_to?(:count) ? number_with_delimiter(pas.count) : pas
  end

  def theme(key)
    THEMATIC_AREAS[key]
  end
end