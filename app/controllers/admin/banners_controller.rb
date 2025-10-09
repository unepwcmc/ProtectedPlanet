class Admin::BannersController < Comfy::Admin::Cms::BaseController
  before_action :build_banner,  only: %i[new create]
  before_action :load_banner,   only: %i[edit update destroy]

  def index
    @banners = Banner.page(params[:page])
  end


  def new
    render
  end

  def edit
    render
  end

  def create
    @banner.save!
    flash[:success] = 'Banner created'
    redirect_to action: :index
  rescue ActiveRecord::RecordInvalid
    flash.now[:danger] = 'Failed to create Banner'
    render action: :new
  end

  def update
    @banner.update_attributes!(banner_params)
    flash[:success] = 'Banner updated'
    render action: :edit
  rescue ActiveRecord::RecordInvalid
    flash.now[:danger] = 'Failed to update Banner'
    render action: :edit
  end

  def destroy
    @banner.destroy
    flash[:success] = 'Banner deleted'
    redirect_to action: :index
  end

  protected

  def build_banner
    @banner = Banner.new(banner_params)
  end

  def load_banner
    @banner = Banner.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:danger] = 'Banner not found'
    redirect_to action: :index
  end

  def banner_params
    params.fetch(:banner, {}).permit(:title, :content, :is_active)
  end
end
