class RegionController < ApplicationController
  before_action :load_vars

  def show
    @presenter = RegionPresenter.new @region

    @iucn_categories = @region.protected_areas_per_iucn_category

    @governance_types = @region.protected_areas_per_governance

    @sources = [
      {
        title: 'Source name',
        date_updated: '2019',
        url: 'http://link-to-source.com'
      }
    ]

    @total_oecm = 0 ##TODO
    @total_wdpa = @region.protected_areas.count

    @wdpa = get_wdpa
  end

  private

  def load_vars
    params[:iso]!="GL" or raise_404
    @region = Region.where(iso: params[:iso].upcase).first
    @region or raise_404
    @presenter = RegionPresenter.new @region
  end

  def get_wdpa
    id = @region.id

    ProtectedArea.joins(:countries).where("countries.region_id = #{id}").order(:name).first(3)
  end
end
