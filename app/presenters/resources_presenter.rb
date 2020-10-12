class ResourcesPresenter
  def initialize(cms_site, all=false)
    @cms_site = cms_site
    @all = all
  end

  def resources
    resources_page = cms_site.pages.find_by_slug('resources')
    published_pages = resources_page.children.published
    sorted_cards = published_pages.sort_by { |c| c.fragments.where(identifier: 'published_date').first&.datetime }.reverse
    selected_cards = limit = all ? sorted_cards : sorted_cards.first(4)

    {
      title: resources_page.label,
      url: all ? '' : resources_page.full_path,
      total: 4,
      cards: selected_cards.map do |page|
        {
          title: page.label,
          page: page
        }
      end
    }
  end

  private

  def cms_site
    @cms_site
  end

  def all
    @all
  end
end