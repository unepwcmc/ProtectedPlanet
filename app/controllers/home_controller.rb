class HomeController < ApplicationController
  after_filter :enable_caching

  def index
  end
end
