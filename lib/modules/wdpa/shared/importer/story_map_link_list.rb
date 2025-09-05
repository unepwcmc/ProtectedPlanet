# frozen_string_literal: true

module Wdpa
  module Shared
    module Importer
      class StoryMapLinkList
        STORY_MAP_LINK_LIST_SITES_CSV = "#{Rails.root}/lib/data/seeds/story_map_link_sites.csv"

        def self.import_live
          result = import_data(ProtectedArea, StoryMapLink)
          Rails.logger.info "Live story map links import completed: #{result[:links_processed]} processed, #{result[:links_created]} created, #{result[:sites_not_found]} sites not found"
          result
        end

        def self.import_staging
          result = import_data(Staging::ProtectedArea, Staging::StoryMapLink)
          Rails.logger.info "Staging story map links import completed: #{result[:links_processed]} processed, #{result[:links_created]} created, #{result[:sites_not_found]} sites not found"
          result
        end

        def self.import_data(protected_area_class, story_map_link_class)
          links_processed = 0
          sites_not_found = 0
          sites_not_found_list = []

          ActiveRecord::Base.transaction do
            csv = CSV.read(STORY_MAP_LINK_LIST_SITES_CSV)
            csv.shift # remove headers

            csv.each do |row|
              links_processed += 1
              site_id = begin
                Integer(row[0])
              rescue StandardError
                false
              end
              protected_area = protected_area_class.find_by_wdpa_id(site_id)

              if protected_area.present?
                story_map_link_class.where(protected_area: protected_area, link: row[1], link_type: row[2])
                  .first_or_create
              else
                sites_not_found += 1
                sites_not_found_list << row[0]
                Rails.logger.warn "Protected Area with site_id #{row[0]} doesn't exist"
              end
            end
          end

          {
            success: true,
            links_processed: links_processed,
            sites_not_found: sites_not_found,
            sites_not_found_list: sites_not_found_list.uniq
          }
        end
      end
    end
  end
end
