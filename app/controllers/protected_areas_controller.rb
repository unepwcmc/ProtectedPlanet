class ProtectedAreasController < ApplicationController
  def show
    slug = params[:id]
    @protected_area = ProtectedArea.where(slug: slug).first
  end
end
