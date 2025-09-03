module Wdpa::Shared::Importer::OverseasTerritories
  OVERSEAS_TERRITORIES_CSV = "#{Rails.root}/lib/data/seeds/overseas_territories.csv".freeze
  extend self

  def import
    ActiveRecord::Base.transaction do
      csv = CSV.read(OVERSEAS_TERRITORIES_CSV)
      csv.shift # remove headers

      csv.each do |parent_iso, child_isos|
        parent_country = Country.find_by_iso_3(parent_iso)
        child_isos = child_isos.split(';')

        next if parent_country.nil?
        child_isos.each do |child_iso|
          child_country = Country.find_by_iso_3(child_iso)

          next if child_country.nil? || parent_country.children.map(&:iso_3).include?(child_iso)
          parent_country.children << child_country
          puts "Added #{child_country.iso_3} to parent #{parent_country.iso_3}"
        end
      end
    end
  end

end