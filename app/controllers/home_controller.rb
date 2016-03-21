class HomeController < ApplicationController
  after_filter :enable_caching

  def index
    @connectivity_page = Comfy::Cms::Page.find_by_label("Connectivity Conservation")
  end
end
