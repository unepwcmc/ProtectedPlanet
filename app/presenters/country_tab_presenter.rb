class CountryTabPresenter < CountryPresenter
  include CountriesHelper
  include Rails.application.routes.url_helpers

  def initialize(country)
    @country = country
    @country_presenter = CountryPresenter.new(country)
  end

  def coverage(oecms_tab: false)
    combined = oecms_tab ? 'combined_' : nil

    [
      country_presenter.send("terrestrial_#{combined}stats"),
      country_presenter.send("marine_#{combined}stats")
    ]
  end

  def message(oecms_tab: false)
    {
      documents: country_presenter.documents, #need to add translated text for link to documents hash 
      text: oecms_tab ? I18n.t('stats.warning_wdpa_oecm') : I18n.t('stats.warning')
    }
  end

  def iucn(oecms_tab: false)
    {
      chart: country_presenter.iucn_categories_chart(@country.protected_areas_per_iucn_category(exclude_oecms: !oecms_tab)),
      country: @country.name,
      categories: create_chart_links(@country.protected_areas_per_iucn_category(exclude_oecms: !oecms_tab)), 
      title: I18n.t('stats.iucn-categories.title')
    }
  end

  def governance(oecms_tab: false)
    {
      chart: country_presenter.governance_chart(@country.protected_areas_per_governance(exclude_oecms: !oecms_tab)),
      country: @country.name,
      governance: create_chart_links(@country.protected_areas_per_governance(exclude_oecms: !oecms_tab)), 
      title: I18n.t('stats.governance.title')
    }
  end

  def sources(oecms_tab: false)
    sources = @country.sources_per_country(exclude_oecms: !oecms_tab)

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
      designations: create_chart_links(country_presenter.designations(exclude_oecms: !oecms_tab), true),
      title: I18n.t('stats.designations.title')
    }
  end

  def growth(oecms_tab: false)
    {
      chart: country_presenter.coverage_growth_chart(exclude_oecms: !oecms_tab), 
      smallprint: I18n.t('stats.coverage-chart-smallprint'),
      title: oecms_tab ? I18n.t('stats.growth.title_wdpa_oecm') : I18n.t('stats.growth.title_wdpa')
    }
  end

  def sites(oecms_tab: false)
    {
      cards: site_cards(3, oecms_tab),
      title: @country.name + ' ' + 
      ( oecms_tab ?  I18n.t('global.area-types.wdpa_oecm') : I18n.t('global.area-types.wdpa')),
      view_all: oecms_tab ? view_all_link : view_all_link(db_type: ['wdpa']),
      text_view_all: I18n.t('global.button.all')
    }
  end

  private

  def country_presenter
    @country_presenter
  end

  def designation_percentages(exclude_oecms)
    country_presenter.designations(exclude_oecms: !exclude_oecms).map do |designation|
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
        @country.protected_areas.oecms.first,
        @country.protected_areas.take(2)
      ].flatten
    else
      @country.protected_areas.order(:name).first(size)
    end
  end
end