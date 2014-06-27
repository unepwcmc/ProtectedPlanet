class HomeController < ApplicationController
  def index
    @number_of_pas = Stats::Global.pa_count
    @number_of_designations = Stats::Global.designation_count
  end
end
