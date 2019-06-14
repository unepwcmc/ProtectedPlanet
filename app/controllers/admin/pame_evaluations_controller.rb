class Admin::PameEvaluationsController < Comfy::Admin::Cms::BaseController
    before_action :build_file,  :only => [:new, :create]
    before_action :build_pame_evaluation,  :only => [:new, :create]
    before_action :load_pame_evaluation,   :only => [:show, :edit, :update, :destroy]
  
    def index
      @pame_evaluations = PameEvaluation.order('id ASC').paginate(page: 1, per_page: 50)
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
      @pame_evaluation.save!
      flash[:success] = 'PameEvaluation Upload saved'
      redirect_to :action => :show, :id => @pame_evaluation
    rescue ActiveRecord::RecordInvalid
      flash.now[:danger] = 'Failed to create PameEvaluation Upload'
      render :action => :new
    end
  
    def update
      @pame_evaluation.update_attributes!(pame_evaluation_params)
      flash[:success] = 'PameEvaluation Upload updated'
      redirect_to :action => :show, :id => @pame_evaluation
    rescue ActiveRecord::RecordInvalid
      flash.now[:danger] = 'Failed to update PameEvaluation Upload'
      render :action => :edit
    end
  
    def destroy
      @pame_evaluation.destroy
      flash[:success] = 'PameEvaluation Upload deleted'
      redirect_to :action => :index
    end
  
  protected
  
    def build_file
      @file = @site.files.new(file_params)
    end

    def build_pame_evaluation
      @pame_evaluation = PameEvaluation.new(pame_evaluation_params)
      @pame_evaluation.comfy_cms_file_id = @file.id
      @pame_evaluation.save
    end
  
    def load_pame_evaluation
      @pame_evaluation = PameEvaluation.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:danger] = 'Pame Evaluation Upload not found'
      redirect_to :action => :index
    end
  
    def pame_evaluation_params
      params.fetch(:pame_evaluation, {}).permit(:id)
    end

    def file_params
      file = params[:file]
      unless file.is_a?(Hash) || file.respond_to?(:to_unsafe_hash)
        params[:file] = { }
        params[:file][:file] = file
      end
      params.fetch(:file, {}).permit!
    end  
  end