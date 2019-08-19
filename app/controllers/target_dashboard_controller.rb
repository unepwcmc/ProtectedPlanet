class TargetDashboardController < ApplicationController
  def index
    @countries = CountrySerializer.new.serialize
  end
end
