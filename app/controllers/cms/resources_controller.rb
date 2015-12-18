class Cms::ResourcesController < ApplicationController
  def index
    @section = 'Publications'
    @resources = Comfy::Cms::Page.all.reject(&:root?)
  end
end
