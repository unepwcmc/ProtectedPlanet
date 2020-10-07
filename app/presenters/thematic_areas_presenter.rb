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
        pas_no: pas_figure(c.slug)
      }
    end
  end

  # Finds by slug rather than by label - which is more likely to change after all
  THEMATIC_AREAS = %w(wdpa protected-areas-management-effectiveness-pame oecms
    indigenous-and-community-conserved-areas global-partnership-on-aichi-target-11
    green-list connectivity-conservation equity marine-protected-areas).freeze

  def pas_figure(slug)
    pas = ProtectedArea
    pas = case slug
    when 'marine-protected-areas'
      pas.marine_areas
    when 'green-list'
      pas.green_list_areas
    when 'wdpa'
      pas.wdpas
    when 'oecms'
      pas.oecms
    when 'protected-areas-management-effectiveness-pame'
      pas.with_pame_evaluations
    else
      -1 #Not applicable - hide ribbon
    end

    pas.respond_to?(:count) ? number_with_delimiter(pas.count) : pas
  end
end