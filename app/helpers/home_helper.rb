module HomeHelper
  PAS_CATEGORIES = [
    {
      title_key: :marine,
      filter: 'marine',
      cms_slug: PageSlugs::ThematicAreas::MARINE
    },
    {
      title_key: :terrestrial,
      filter: 'terrestrial',
      cms_slug: nil,
      use_this_image: 'terrestrial.jpg'
    },
    {
      title_key: :green_list,
      filter: 'pa_or_any_its_parcels_is_greenlisted',
      is_green_list: true,
      cms_slug: PageSlugs::ThematicAreas::EFFECTIVENESS
    }
  ].freeze

  def pas_categories
    PAS_CATEGORIES.map do |category|
      {
        image: pas_category_image(category),
        title: t("home.pas.categories.#{category[:title_key]}"),
        url: search_areas_path(filters: SearchAreaLinkFilters.home_category_filters(
          filter: category[:filter],
          is_green_list: category.fetch(:is_green_list, false)
        ))
      }
    end
  end

  private

  def pas_category_image(category)
    return image_path(category[:use_this_image]) if category[:use_this_image].present?
    return '' if category[:cms_slug].blank?

    cms_page = Comfy::Cms::Page.find_by(slug: category[:cms_slug])
    return '' if cms_page.blank?

    cms_fragment_render(:image, cms_page).presence || ''
  rescue StandardError
    ''
  end
end
