class ThematicalAreasPresenter
  include ActionView::Helpers::NumberHelper

  def initialize(cms_site)
    @cms_site = cms_site
  end

  def thematical_areas
    thematical_page = @cms_site.pages.find_by_slug('thematical-areas')
    ##TODO FERDI can you fill in this bit - not needed for ICCA registry
    ## Update variable in the view /partials/sub_partials/_themes.html.erb
    items = {
      "title": thematical_page.label,
      "cards": cards(thematical_page)
    }
  end

  private

  def cards(thematical_page)
    _cards = thematical_page.children.published
    _cards.map do |c|
      {
        obj: c,
        pas_no: pas_figure(c.label)
      }
    end
  end

  THEMATICAL_AREAS = {
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
    THEMATICAL_AREAS[key]
  end
end