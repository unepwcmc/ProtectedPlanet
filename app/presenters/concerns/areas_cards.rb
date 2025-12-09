module Concerns
  module AreasCards
    extend ActiveSupport::Concern

    included do
      include ActionView::Helpers::NumberHelper
    end

    private

    def area_payload(slug, fallback_title: nil)
      page = @cms_site.pages.find_by_slug(slug)
      return { title: fallback_title || slug.humanize, cards: [] } if page.nil?

      {
        title: page.label,
        cards: cards(page)
      }
    end

    def cards(pages)
      pages.children.published.map do |c|
        {
          obj: c,
          pas_no: pas_figure(c.slug)
        }
      end
    end

    def pas_figure(slug)
      pas = ProtectedArea
      pas = case slug
            when PageSlugs::MARINE_PROTECTED_AREAS
              pas.marine_areas
            when PageSlugs::GREEN_LIST
              pas.green_list_areas
            when PageSlugs::WDPCA
              pas
            when PageSlugs::EFFECTIVENESS
              pas.with_pame_evaluations
            else
              -1 #Not applicable - hide ribbon
            end

      pas.respond_to?(:count) ? number_with_delimiter(pas.count) : pas
    end
  end
end