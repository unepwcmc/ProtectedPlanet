class RegionController < ApplicationController
  before_action :load_vars

  def show
    @iucn_categories = @region.protected_areas_per_iucn_category
    @governance_types = @region.protected_areas_per_governance

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
    @designations_by_jurisdiction = @region.designations.group_by { |design|
      design.jurisdiction.name rescue "Not Reported"
    }
  end

end
