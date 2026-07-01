class ThematicAreasPresenter
  include ActionView::Helpers::NumberHelper

  def initialize(cms_site)
    @cms_site = cms_site
  end

  def thematic_areas
    build_collection(PageSlugs::ThematicAreas::PARENT)
  end

  def databases
    build_collection(PageSlugs::Databases::PARENT)
  end

  def all_cards
    thematic_page = parent_page(PageSlugs::ThematicAreas::PARENT)
    database_page = parent_page(PageSlugs::Databases::PARENT)

    combined_cards = []
    combined_cards.concat(cards(database_page)) if database_page
    combined_cards.concat(cards(thematic_page)) if thematic_page

    {
      title: I18n.t('global.carousels_all_cards_title'),
      cards: combined_cards
    }
  end

  private

  def build_collection(parent_slug)
    parent_page = parent_page(parent_slug)
    return { title: nil, cards: [] } if parent_page.nil?

    {
      title: parent_page.label,
      cards: cards(parent_page)
    }
  end

  def parent_page(slug)
    @cms_site.pages.find_by_slug(slug)
  end

  def cards(parent_page)
    parent_page.children.published.map do |c|
      {
        obj: c,
        pas_no: pas_figure(c.slug)
      }
    end
  end

  def pas_figure(slug)
    # TODO: update here once NC knows what they want to show in home page
    scope = case slug
            when PageSlugs::Databases::WDPCA
              ProtectedArea.all
            when PageSlugs::Databases::GDPAME
              ProtectedArea.pas_with_pame_on_self_or_any_parcel
            when PageSlugs::ThematicAreas::MARINE
              ProtectedArea.marine_areas
            else
              return -1
            end

    number_with_delimiter(scope.count)
  end
end
