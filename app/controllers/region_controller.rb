class RegionController < ApplicationController
  before_filter :load_vars

  def show
  end

  private

  def load_vars
    @region = Region.where(iso: params[:iso].upcase).first
    @region or raise_404
    @presenter = RegionPresenter.new @region
  end

end
