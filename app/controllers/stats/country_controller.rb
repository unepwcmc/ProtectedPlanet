class Stats::CountryController < ApplicationController
  def show
    iso = params[:iso]

    @country =  Country.where(iso: iso).first
    @number_of_pas = Stats::Country.total_pas iso
    @pas_with_iucn_category = Stats::Country.pas_with_iucn_category iso
    @number_of_designations = Stats::Country.designation_count iso
    @designations_by_frequency = Stats::Country.protected_areas_by_designation iso
  end
end
