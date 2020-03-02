class RegionController < ApplicationController
  before_action :load_vars

  def show
    presenter = RegionPresenter.new @region

    @iucn_categories = @region.protected_areas_per_iucn_category
    @governance_types = @region.protected_areas_per_governance

    @marine_stats = {
      protected_km2: presenter.pa_marine_area.round(0),
      protected_percentage: presenter.percentage_pa_marine_cover.round(2),
      total_km2: presenter.marine_area.round(0)
    }

    @terrestrial_stats = {
      protected_km2: presenter.pa_land_area.round(0),
      protected_percentage: presenter.percentage_pa_land_cover.round(2),
      total_km2: presenter.land_area.round(0)
    }

    @designations = [
      {
        title: 'National designations',
        total: get_designation_total('National'),
        has_jurisdiction: has_jurisdiction('National'),
        jurisdictions: get_jurisdictions('National')
      }, 
      {
        title: 'Regional designations',
        total: get_designation_total('Regional'),
        has_jurisdiction: has_jurisdiction('Regional'),
        jurisdictions: get_jurisdictions('Regional')
      },
      {
        title: 'International designations',
        total: get_designation_total('International'),
        has_jurisdiction: has_jurisdiction('International'),
        jurisdictions: get_jurisdictions('International')
      }
    ]

    # protected_national_report: presenter.percentage_nr_marine_cover,
    # national_report_version: presenter.nr_version,

    # if(has_pame_stats) {
    #   @marine_stats['pame_protected_km2'] = presenter.pame_statistic.pame_percentage_pa_marine_cover.round(2)
    #   @marine_stats['pame_protected_percentage'] = presenter.pame_statistic.pame_pa_marine_area,
    # }

    @sources = [
      {
        title: 'Source name',
        date_updated: '2019',
        url: 'http://link-to-source.com'
      }
    ]
  end

  private

  def load_vars
    params[:iso]!="GL" or raise_404
    @region = Region.where(iso: params[:iso].upcase).first
    @region or raise_404
    @presenter = RegionPresenter.new @region
  end

  def designations
    designations_by_jurisdiction = @region.designations.group_by { |design|
      design.jurisdiction.name rescue "Not Reported"
    }
  end

  def has_jurisdiction type 
    Jurisdiction.find_by_name(type)
  end

  def get_designation_total type
    if designations.include? type then
      designations[type].count
    else
      0
    end
  end

  def get_jurisdictions type
    jurisdiction = has_jurisdiction type
    
    if jurisdiction
      @region.protected_areas_per_designation(jurisdiction)
    else
      []
    end
  end
end
