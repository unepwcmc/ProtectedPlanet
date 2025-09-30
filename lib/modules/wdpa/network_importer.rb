#  TODO: Remove NetworkImporter as CSV is no longer being used to import networks

module Wdpa::NetworkImporter
  TRANSBOUNDARY_SITES_CSV = "#{Rails.root}/lib/data/seeds/transboundary_sites.csv".freeze
  extend self

  def import
    ActiveRecord::Base.transaction do
      Network.all.each(&:destroy)

      csv = CSV.read(TRANSBOUNDARY_SITES_CSV)
      csv.shift # remove headers

      networks_by_site_id = {}
      pas_cache = {}

      pa_couples = csv.map { |row| [row[0], row[1]] }.map(&:sort).uniq

      pa_couples.each do |site1, site2|
        next if site1 == site2

        pa1 = (pas_cache[site1] ||= ProtectedArea.find_by(site_id: site1))
        pa2 = (pas_cache[site2] ||= ProtectedArea.find_by(site_id: site2))

        next unless pa1 && pa2

        network1 = networks_by_site_id[site1]
        network2 = networks_by_site_id[site2]
        next if network1.present? && network1 == network2

        if network1.present?
          network1.protected_areas << pa2
          networks_by_site_id[site2] = network1

        elsif network2.present?
          network2.protected_areas << pa1
          networks_by_site_id[site1] = network2

        else
          network = Network.create(name: "Transboundary sites")

          network.protected_areas << pa1
          network.protected_areas << pa2

          networks_by_site_id[site1] = network
          networks_by_site_id[site2] = network
        end
      end
    end
  end
end
