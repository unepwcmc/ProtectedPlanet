module Wdpa::StoryMapLinkListImporter
  STORY_MAP_LINK_LIST_SITES_CSV = "#{Rails.root}/lib/data/seeds/story_map_link_sites.csv"
  extend self

  def import
    ActiveRecord::Base.transaction do
      csv = CSV.read(STORY_MAP_LINK_LIST_SITES_CSV)
      csv.shift # remove headers

      csv.each do |row|
        wdpa_id = Integer(row[0]) rescue false
        if wdpa_id
          pa = ProtectedArea.find_by_wdpa_id(wdpa_id)
        else
          pa = ProtectedArea.find_by_slug(row[0])
        end

        unless pa.blank?
          pa.story_map_link = row[1]
          pa.save
          puts "Added this link #{row[1]} to #{row[0]}"
        end
      end
    end
  end
end
