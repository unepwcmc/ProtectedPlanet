class RegionController < ApplicationController
  before_action :load_vars

  def show
    @iucn_categories = @region.protected_areas_per_iucn_category

    @governance_types = @region.protected_areas_per_governance

    @designations = @presenter.designations

    # For the stacked row chart percentages
    @designation_percentages = @designations.map do |designation|
      { percent: designation[:percent] }
    end.to_json

    @sources = [
      {
        title: 'Source name',
        date_updated: '2019',
        url: 'http://link-to-source.com'
      }
    ]

    @total_oecm = 0 ##TODO
    @total_pame = @region.protected_areas.with_pame_evaluations.count
    @total_wdpa = @region.protected_areas.count

    @wdpa = pas_sample

    helpers.opengraph_title_and_description_with_suffix(@region.name)
  end

  private

  def load_vars
    params[:iso]!="GL" or raise_404
    @region = Region.where(iso: params[:iso].upcase).first
    @region or raise_404
    @presenter = RegionPresenter.new @region
  end

  def pas_sample(size=3)
    ProtectedArea.joins(:countries).
      where("countries.region_id = #{@region.id}").
      order(:name).first(size)
  end
end
