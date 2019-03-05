module Wdpa::StoryMapLinkListImporter
  STORY_MAP_LINK_LIST_SITES_CSV = "#{Rails.root}/lib/data/seeds/story_map_link_sites.csv"
  extend self

  def import
    ActiveRecord::Base.transaction do
      csv = CSV.read(STORY_MAP_LINK_LIST_SITES_CSV)
      csv.shift # remove headers

      csv.each do |row|
        wdpa_id = Integer(row[0]) rescue false
        unless ProtectedArea.find_by_wdpa_id(wdpa_id).blank?
          StoryMapLink.where(wdpa_id: wdpa_id, link: row[1])
                      .first_or_create
          puts "Added this link #{row[1]} to #{wdpa_id}"
        else
          puts "Protected Area with wdpa_id #{row[0]} doesn't exist"
        end
      end
    end
  end
end
