class Cms::ResourcesController < ApplicationController
  before_filter :load_category

  def index
    @resources = Comfy::Cms::Page
      .for_category(@category.label)
      .reject(&:root?)
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
end
