class TabPresenter
  include CountriesHelper
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::AssetTagHelper

  def initialize(geo_entity)
    @geo_entity = geo_entity
    @presenter = nil

    @presenter = if geo_entity.instance_of?(::Country)
                   CountryPresenter.new(geo_entity)
                 else
                   RegionPresenter.new(geo_entity)
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
      documents: presenter.try(:documents), # need to add translated text for link to documents hash
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
    {
      count: sources_per_geo_entity(exclude_oecms: !oecms_tab).count,
      source_updated: I18n.t('stats.sources.updated'),
      sources: sources_per_geo_entity(exclude_oecms: !oecms_tab),
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
      site_details: fetch_site_names_and_site_ids(3, oecms_tab),
      title: other_sites_title(oecms_tab),
      view_all: oecms_tab ? view_all_link : view_all_link(db_type: ['wdpa']),
      text_view_all: I18n.t('global.button.all')
    }
  end

  private

  def sources_per_geo_entity(exclude_oecms: false)
    if @geo_entity.instance_of?(::Country)
      @geo_entity.sources_per_country(exclude_oecms: exclude_oecms)
    else
      @geo_entity.sources_per_region(exclude_oecms: exclude_oecms)
    end
  end

  def other_sites_title(oecms_tab)
    text = oecms_tab ? I18n.t('global.area-types.wdpa_oecm') : I18n.t('global.area-types.wdpa')
    @geo_entity.name + ' ' + text
  end

  attr_reader :presenter

  def designation_percentages(exclude_oecms)
    presenter.designations(exclude_oecms: !exclude_oecms).map do |designation|
      { percent: designation[:percent] }
    end
  end

  def create_chart_links(input_data, is_designations = false)
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

  def fetch_site_names_and_site_ids(size, show_oecm)
    protected_areas = []

    if show_oecm
      oecms = @geo_entity.related_protected_areas_without_geometry(limit: 1, &:oecms)
      related_protected_areas = @geo_entity.related_protected_areas_without_geometry(limit: size - 1)

      protected_areas << oecms
    else
      related_protected_areas = @geo_entity.related_protected_areas_without_geometry(limit: size)
    end

    protected_areas << related_protected_areas

    protected_areas.flatten.map { |protected_area| protected_area_to_tab(protected_area) }
  end

  def protected_area_to_tab(protected_area)
    {
      name: protected_area[:name],
      site_id: protected_area[:site_id],
      thumbnail_link: ApplicationController.helpers.protected_area_cover(protected_area, with_tag: false)
    }
  end
end
