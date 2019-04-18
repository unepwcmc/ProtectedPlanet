class Admin::HistoricWdpaReleasesController < Comfy::Admin::Cms::BaseController

  before_action :build_historic_wdpa_release,  :only => [:new, :create]
  before_action :set_select_options,  :except => [:index, :show, :destroy]
  before_action :load_historic_wdpa_release,   :only => [:show, :edit, :update, :destroy]

  def index
    @historic_wdpa_releases = HistoricWdpaRelease.page(params[:page])
  end

  def show
    render
  end

  def new
    render
  end

  def edit
    render
  end

  def create
    @historic_wdpa_release.save!
    flash[:success] = 'Historic Wdpa Release created'
    redirect_to :action => :show, :id => @historic_wdpa_release
  rescue ActiveRecord::RecordInvalid
    flash.now[:danger] = 'Failed to create Historic Wdpa Release'
    render :action => :new
  end

  def update
    @historic_wdpa_release.update_attributes!(historic_wdpa_release_params)
    flash[:success] = 'Historic Wdpa Release updated'
    redirect_to :action => :show, :id => @historic_wdpa_release
  rescue ActiveRecord::RecordInvalid
    flash.now[:danger] = 'Failed to update Historic Wdpa Release'
    render :action => :edit
  end

  def destroy
    @historic_wdpa_release.destroy
    flash[:success] = 'Historic Wdpa Release deleted'
    redirect_to :action => :index
  end

protected

  def build_historic_wdpa_release
    @historic_wdpa_release = HistoricWdpaRelease.new(historic_wdpa_release_params)
  end

  def load_historic_wdpa_release
    @historic_wdpa_release = HistoricWdpaRelease.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:danger] = 'Historic Wdpa Release not found'
    redirect_to :action => :index
  end

  def historic_wdpa_release_params
    params.fetch(:historic_wdpa_release, {}).permit(:url, :month, :year)
  end

  def set_select_options
    @year_select_options = year_select_options
    @month_select_options = month_select_options
  end

  def month_select_options
    Date::MONTHNAMES.each_with_index.map { |name, index| [name, index] }.drop(1)
  end

  def year_select_options
    [*2015..(Date.today.year + 1)]
  end
end