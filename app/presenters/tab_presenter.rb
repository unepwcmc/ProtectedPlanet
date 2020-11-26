class TabPresenter 
  include CountriesHelper
  include Rails.application.routes.url_helpers

  def initialize(geo_entity)
    @geo_entity = geo_entity
    @presenter = nil
    
    if geo_entity.class.to_s == 'Country'
      @presenter = CountryPresenter.new(geo_entity)
    else
      @presenter = RegionPresenter.new(geo_entity)
    end
  end

  def coverage(oecms_tab: false)
    combined = oecms_tab ? 'combined_' : nil

    [
      presenter.send("build_#{combined}stats", 'land'),
      presenter.send("build_#{combined}stats", 'marine')
    ]
  end

  def message(oecms_tab: false)
    {
      documents: presenter.documents, #need to add translated text for link to documents hash 
      text: oecms_tab ? I18n.t('stats.warning_wdpa_oecm') : I18n.t('stats.warning')
    }
  end

  def iucn(oecms_tab: false)
    {
      chart: presenter.iucn_categories_chart(@geo_entity.protected_areas_per_iucn_category(exclude_oecms: !oecms_tab)),
      country: @geo_entity.name,
      categories: create_chart_links(@geo_entity.protected_areas_per_iucn_category(exclude_oecms: !oecms_tab)), 
      title: I18n.t('stats.iucn-categories.title')
    }
  end

  def governance(oecms_tab: false)
    {
      chart: presenter.governance_chart(@geo_entity.protected_areas_per_governance(exclude_oecms: !oecms_tab)),
      country: @geo_entity.name,
      governance: create_chart_links(@geo_entity.protected_areas_per_governance(exclude_oecms: !oecms_tab)), 
      title: I18n.t('stats.governance.title')
    }
  end

  def sources(oecms_tab: false)
    sources = @geo_entity.sources_per_country(exclude_oecms: !oecms_tab)

    {
      count: sources.count,
      source_updated: I18n.t('stats.sources.updated'),
      sources: sources,
      title: I18n.t('stats.sources.title')
    }
  end

  def designations(oecms_tab: false)
    {
      chart: designation_percentages(oecms_tab),
      designations: create_chart_links(presenter.designations(exclude_oecms: !oecms_tab), true),
      title: I18n.t('stats.designations.title')
    }
  end

  def growth(oecms_tab: false)
    {
      chart: presenter.coverage_growth_chart(exclude_oecms: !oecms_tab), 
      smallprint: I18n.t('stats.coverage-chart-smallprint'),
      title: oecms_tab ? I18n.t('stats.growth.title_wdpa_oecm') : I18n.t('stats.growth.title_wdpa')
    }
  end

  def sites(oecms_tab: false)
    {
      cards: site_cards(3, oecms_tab),
      title: other_sites_title(oecms_tab),
      view_all: oecms_tab ? view_all_link : view_all_link(db_type: ['wdpa']),
      text_view_all: I18n.t('global.button.all')
    }
  end

  private

  def other_sites_title(oecms_tab)
    text = oecms_tab ?  I18n.t('global.area-types.wdpa_oecm') : I18n.t('global.area-types.wdpa')
    @geo_entity.name + ' ' + text
  end

  def presenter
    @presenter
  end

  def designation_percentages(exclude_oecms)
    presenter.designations(exclude_oecms: !exclude_oecms).map do |designation|
      { percent: designation[:percent] }
    end
  end

  def create_chart_links(input_data, is_designations=false)
    if is_designations
      input_data.map do |j|
        jurisdictions_with_links = { 
          jurisdictions: merge_chart_links(j[:jurisdictions]) 
        }           
        j.merge!(jurisdictions_with_links)        
      end
    else
      merge_chart_links(input_data)
    end
  end

  def merge_chart_links(input)
    input.map do |category|
      category.merge!({
        link: chart_link(category)[:link],
        title: chart_link(category)[:title]
      })
    end
  end

  def site_cards(size = 3, show_oecm = true)
    if show_oecm 
      [
        @geo_entity.protected_areas.oecms.first,
        @geo_entity.protected_areas.take(2)
      ].flatten
    else
      @geo_entity.protected_areas.order(:name).first(size)
    end
  end
end