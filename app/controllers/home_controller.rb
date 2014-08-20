class HomeController < ApplicationController
  after_filter :enable_caching

  def index
    @number_of_pas = ProtectedArea.count
    @number_of_designations = Designation.count
    @pas_with_iucn_category = ProtectedArea.with_valid_iucn_categories.count
    @countries_providing_data = Country.data_providers.count
  end
end
