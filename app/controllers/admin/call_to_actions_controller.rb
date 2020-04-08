class Admin::CallToActionsController < Comfy::Admin::Cms::BaseController
  before_action :build_cta,  :only => [:new, :create]
  before_action :load_cta,   :only => [:show, :edit, :update, :destroy]

  def index
    @ctas = CallToAction.page(params[:page])
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
    flash[:success] = 'Call To Action created'
    redirect_to action: :show, id: @cta
  rescue ActiveRecord::RecordInvalid
    flash.now[:danger] = 'Failed to create Call To Action'
    render action: :new
  end

  def update
    @cta.update_attributes!(cta_params)
    flash[:success] = 'Call To Action updated'
    redirect_to action: :show, id: @cta
  rescue ActiveRecord::RecordInvalid
    flash.now[:danger] = 'Failed to update Call To Action'
    render action: :edit
  end

  def destroy
    @cta.destroy
    flash[:success] = 'Call To Action deleted'
    redirect_to action: :index
  end

  protected

  def build_cta
    @cta = CallToAction.new(cta_params)
  end

  def load_cta
    @cta = CallToAction.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:danger] = 'Call To Action not found'
    redirect_to action: :index
  end

  def cta_params
    params.fetch(:call_to_action, {}).permit(:css_class, :title, :summary, :url, :updated)
  end
end
