class HomeController < ApplicationController
  def index
    home_yml = I18n.t('home')

    @total_pas = 'XXXXXX' #TODO replace with correct integer
    @total_oecms = 'XXXXXX' #TODO replace with correct integer

    @pas_title = home_yml[:pas][:title]
    @pas_button = home_yml[:pas][:button]
    @pas_levels = home_yml[:pas][:levels]
    @pas_categories = home_yml[:pas][:categories]

    comfy_news = Comfy::Cms::Page.find_by_slug("blog")
    @news_articles_title = comfy_news.label
    @news_articles_url = comfy_news.full_path
    @news_articles = comfy_news.children.published.order(created_at: :desc).limit(2) #TODO replace with correct pages #TODO get ordering to work

    comfy_news = Comfy::Cms::Page.find_by_slug("resources")
    @resources_title = comfy_news.label
    @resources_url = comfy_news.full_path
    @resources = comfy_news.children.published.order(created_at: :desc).limit(4) #TODO replace with correct pages #TODO get ordering to work
    
    @regions_page = Comfy::Cms::Page.find_by_slug("unep-regions")

    @thematicAreas = [
      {
        title: t('thematic_area.target_11_dashboard.title'),
        content: t('thematic_area.target_11_dashboard.description'),
        image: t('thematic_area.target_11_dashboard.thematic_image'),
        url: target_dashboard_path
      },
      {
        title: "WDPA",
        content: "The World Database on Protected Areas (WDPA) is the most
                  comprehensive global database on terrestrial and marine protected
                  areas.",
        image: "wdpa.jpg",
        url: Rails.root.join("/c#{@wdpa_page.try(:full_path)}")
      },
      {
        title: "Marine Protected Areas",
        content: "Explore the World's marine protected areas",
        image: "marine.png",
        url: marine_path
      },
      {
        title: "ICCAs",
        content: "The ICCA Registry is an online platform for indigenous
          peoples’ and community conserved territories and areas, where
          communities themselves provide data, case studies, maps, photos
          and stories.",
        image: "icca.jpg",
        url: "http://www.iccaregistry.org"
      },
      {
        title: "PAME",
        content: "PAME is a global database, comprising many thousands of
        assessments of how well a protected area is being managed –
        primarily the extent to which it is
        protecting values and achieving goals and objectives.",
        image: "pame.jpg",
        url: Rails.root.join("/c#{@pame_page.try(:full_path)}")
      },
      {
        title: "PARCC",
        content: "The PARCC project's main
          objective was to assess the vulnerability of West African protected
          areas to climate change and help design more resilient protected area networks.",
        image: "parcc.jpg",
        url: "http://parcc.protectedplanet.net/"
      },
      {
        title: "Green List",
        content: "The IUCN Green List is a new global standard for protected areas.
          The list recognizes success in achieving conservation outcomes and
          measures progress in effective management of protected areas.",
        image: "green-list.jpg",
        url: Rails.root.join("/c#{@green_list_page.try(:full_path)}")
      },
      {
        title: "Equity and Protected Areas",
        content: "Equity relates to how fairly a protected area is managed: who has a say in decisions, how decisions are taken, and how the costs and benefits are shared.",
        image: "equity.jpg",
        url: Rails.root.join("/c#{@equity_page.try(:full_path)}")
      }
    ]

    @carousel_slides = HomeCarouselSlide.all.select{|slide| slide.published }

  end
end
