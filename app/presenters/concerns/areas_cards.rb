module Concerns
  module AreasCards
    extend ActiveSupport::Concern

    included do
      include ActionView::Helpers::NumberHelper
    end

    private

    def area_payload(slug, fallback_title: nil)
      page = @cms_site.pages.find_by_slug(slug)
      return nil if page.nil? && fallback_title.nil?

      {
        title: page ? page.label : fallback_title,
        cards: page ? cards(page) : []
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
            when 'marine-protected-areas'
              pas.marine_areas
            when 'green-list'
              pas.green_list_areas
            when 'wdpa'
              pas.wdpas
            when 'wdpca'
              pas
            when 'oecms'
              pas.oecms
            when 'effectiveness'
              pas.with_pame_evaluations
            else
              -1 #Not applicable - hide ribbon
            end

      pas.respond_to?(:count) ? number_with_delimiter(pas.count) : pas
    end
  end
end