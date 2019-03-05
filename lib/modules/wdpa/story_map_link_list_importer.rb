module Wdpa::StoryMapLinkListImporter
  STORY_MAP_LINK_LIST_SITES_CSV = "#{Rails.root}/lib/data/seeds/story_map_link_sites.csv"
  extend self

  def import
    ActiveRecord::Base.transaction do
      csv = CSV.read(STORY_MAP_LINK_LIST_SITES_CSV)
      csv.shift # remove headers

      csv.each do |row|
        StoryMapLink.where(wdpa_id: row[0], link: row[1])
                    .first_or_create
      end
    end
  end
end
