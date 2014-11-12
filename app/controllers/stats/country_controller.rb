class Stats::CountryController < ApplicationController
  before_filter :load_vars
  before_filter :load_user_projects

  def show
  end

  def new_comparison
  end

  def compare
    @comparison_country = Country.where(iso: params[:compare_iso]).first
    @comparison_presenter = StatisticPresenter.new @comparison_country
  end

  private

  def load_vars
    @country = Country.where(iso: params[:iso]).first
    @presenter = StatisticPresenter.new @country
  end
end
