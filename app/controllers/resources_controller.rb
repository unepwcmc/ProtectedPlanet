class ResourcesController < Comfy::Cms::ContentController
  before_action :load_cms_page
  before_action :load_category

  def index
    @all_resources = Comfy::Cms::Page.for_category(@category.label)
    @resources = search(@all_resources).reject(&:root?).reject { |p| p.parent.label != "Index" }
  end

  private

  def load_category
    @category = if params[:category_id]
      Comfy::Cms::Category.find(params[:category_id])
    else
      Comfy::Cms::Category.first
    end
  rescue
    @category = Comfy::Cms::Category.first
  end

  def search resources
    if params[:year]
      resources.where("date_part('year', created_at) = ?", params[:year])
    else
      resources
    end
  end
end
