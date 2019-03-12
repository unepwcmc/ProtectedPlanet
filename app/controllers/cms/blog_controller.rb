class Cms::BlogController < ApplicationController

  def index
    @all_pages = Comfy::Cms::Page.find_by_slug('blog').children
    @blog_pages = search(@all_pages)
  end

  private

  def search pages
    if params[:year]
      pages.where("date_part('year', created_at) = ?", params[:year])
    else
      pages
    end
  end
end
