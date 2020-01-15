class HomeController < ApplicationController
  def index
    home_yml = I18n.t('home')

    @total_pas = 'XXXXXX' #TODO replace with correct integer
    @total_oecms = 'XXXXXX' #TODO replace with correct integer

    search_pas = ProtectedArea.first(4).map{ |pa| {"id": pa.wdpa_id, "name": pa.name} } #TODO make this ALL the pas
    search_oecms = ProtectedArea.last(4).map{ |pa| {"id": pa.wdpa_id, "name": pa.name} } #TODO make this ALL the OECMS
    @search_pas_categories = [
      { name: 'Protected Areas', placeholder: 'Search for a Protected Area', options: search_pas },
      { name: 'OECMs', placeholder: 'Search for an OECM', options: search_oecms }
    ].to_json
    @search_pas_config = { id: 'search-pas' }.to_json

    @pas_title = home_yml[:pas][:title]
    @pas_button = home_yml[:pas][:button]
    @pas_levels = home_yml[:pas][:levels]
    @pas_categories = home_yml[:pas][:categories]

    comfy_themes = Comfy::Cms::Page.find_by_slug("thematic-areas") 
    @themes_title = comfy_themes.label
    @themes_url = comfy_themes.full_path
    @themes = comfy_themes.children.published.map{ |page| {
        "label": page.label, 
        "url": page.url,
        "intro": "field needs created in the CMS", #TODO create field in CMS
        "image": "field needs created in the CMS" #TODO create field in CMS  
      }
    }

    comfy_news = Comfy::Cms::Page.find_by_slug("blog")
    @news_articles_title = comfy_news.label
    @news_articles = comfy_news.children.published.order(created_at: :desc).limit(2).map{ |page| { 
      "label": page.label, 
      "created_at": page.created_at.strftime('%d %B %y'),
      "url": page.url,
      "intro": "field needs created in the CMS", #TODO create field in CMS
      "image": "field needs created in the CMS" #TODO create field in CMS
      }
    } #TODO replace with correct pages #TODO get ordering to work

    comfy_resources = Comfy::Cms::Page.find_by_slug("resources")
    @resources_title = comfy_resources.label
    @resources = comfy_resources.children.published.order(created_at: :desc).limit(4).map{ |page| { 
      "label": page.label, 
      "created_at": page.created_at.strftime('%d %B %y'),
      "url": page.url,
      "intro": "field needs created in the CMS", #TODO create field in CMS
      "pdf": 'yes', #TODO create field in CMS
      "external_link": nil #TODO create field in CMS
      }
    } #TODO replace with correct pages #TODO get ordering to work

    @temp_pas = ProtectedArea.first(4)

    @temp_themes = Comfy::Cms::Page.find_by_slug("equity").children.order(created_at: :desc)
    
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
