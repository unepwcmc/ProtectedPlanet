class HomeController < ApplicationController
  after_filter :enable_caching

  def index
    @regions_page = Comfy::Cms::Page.find_by_slug("unep-regions")

    @thematicAreas = [
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

    @carousel_slides = [
      {
        "title" => "Explore the new monthly release of the WDPA",
        "description" => "With updates on Ukraine and Cameroon's protected area networks.",
        "url" => "https://www.protectedplanet.net/c/monthly-updates/2018/december-2018-update-of-the-wdpa"
      },
      {
        "title" => "Explore the new Protected Planet Digital Report",
        "description" => "The latest Protected Planet Digital Report assesses the current state of protected areas around the world.",
        "url" => "http://livereport.protectedplanet.net"
      },
      {
        "title" => "Explore the new edition of the United Nations List on Protected Areas",
        "description" => "The List includes, for the first time, information on management effectiveness of the world's protected areas.",
        "url" => "https://www.protectedplanet.net/c/united-nations-list-of-protected-areas/united-nations-list-of-protected-areas-2018"
      }
    ]
  end
end
