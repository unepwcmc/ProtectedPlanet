class HomeController < ApplicationController
  after_filter :enable_caching

  def index
    @regions_page = Comfy::Cms::Page.find_by_slug("unep-regions")
  end
end
