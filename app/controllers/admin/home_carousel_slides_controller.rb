class Admin::HomeCarouselSlidesController < Comfy::Admin::Cms::BaseController

  before_action :build_home_carousel_slide,  :only => [:new, :create]
  before_action :load_home_carousel_slide,   :only => [:show, :edit, :update, :destroy]

  def index
    @home_carousel_slides = HomeCarouselSlide.page(params[:page])
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
    @home_carousel_slide.save!
    flash[:success] = 'Home Carousel Slide created'
    redirect_to :action => :show, :id => @home_carousel_slide
  rescue ActiveRecord::RecordInvalid
    flash.now[:danger] = 'Failed to create Home Carousel Slide'
    render :action => :new
  end

  def update
    @home_carousel_slide.update_attributes!(home_carousel_slide_params)
    flash[:success] = 'Home Carousel Slide updated'
    redirect_to :action => :show, :id => @home_carousel_slide
  rescue ActiveRecord::RecordInvalid
    flash.now[:danger] = 'Failed to update Home Carousel Slide'
    render :action => :edit
  end

  def destroy
    @home_carousel_slide.destroy
    flash[:success] = 'Home Carousel Slide deleted'
    redirect_to :action => :index
  end

protected

  def build_home_carousel_slide
    @home_carousel_slide = HomeCarouselSlide.new(home_carousel_slide_params)
  end

  def load_home_carousel_slide
    @home_carousel_slide = HomeCarouselSlide.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:danger] = 'Home Carousel Slide not found'
    redirect_to :action => :index
  end

  def home_carousel_slide_params
    params.fetch(:home_carousel_slide, {}).permit(:title, :description, :url)
  end
end