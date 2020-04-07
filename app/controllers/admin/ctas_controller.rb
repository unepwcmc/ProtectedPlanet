class Admin::CtasController < Comfy::Admin::Cms::BaseController
  before_action :build_cta,  :only => [:new, :create]
  before_action :load_cta,   :only => [:show, :edit, :update, :destroy]

  def index
    @ctas = Cta.page(params[:page])
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
    @cta.save!
    flash[:success] = 'CTA created'
    redirect_to :action => :show, :id => @cta
  rescue ActiveRecord::RecordInvalid
    flash.now[:danger] = 'Failed to create CTA'
    render :action => :new
  end

  def update
    @cta.update_attributes!(cta_params)
    flash[:success] = 'CTA updated'
    redirect_to :action => :show, :id => @cta
  rescue ActiveRecord::RecordInvalid
    flash.now[:danger] = 'Failed to update CTA'
    render :action => :edit
  end

  def destroy
    @cta.destroy
    flash[:success] = 'CTA deleted'
    redirect_to :action => :index
  end

  protected

  def build_cta
    @cta = Cta.new(cta_params)
  end

  def load_cta
    @cta = Cta.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:danger] = 'CTA not found'
    redirect_to :action => :index
  end

  def cta_params
    params.fetch(:cta, {}).permit(:klass, :title, :summary, :url, :updated)
  end
end
