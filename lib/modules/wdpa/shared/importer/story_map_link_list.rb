# frozen_string_literal: true

module Wdpa
  module Shared
    module Importer
      class StoryMapLinkList < Wdpa::Shared::ImporterBase::Base
        STORY_MAP_LINK_LIST_SITES_CSV = "#{Rails.root}/lib/data/seeds/story_map_link_sites.csv"

        def self.import_live
          result = import_data(ProtectedArea, StoryMapLink)
          Rails.logger.info "Live story map links import completed: #{result[:links_processed]} processed, #{result[:links_created]} created, #{result[:sites_not_found]} sites not found"
          result
        end

        def self.import_to_staging
          result = import_data(Staging::ProtectedArea, Staging::StoryMapLink)
          Rails.logger.info "Staging story map links import completed: #{result[:links_processed]} processed, #{result[:links_created]} created, #{result[:sites_not_found]} sites not found"
          result
        rescue StandardError => e
          Rails.logger.error "Story map links import failed: #{e.message}"
          Wdpa::Shared::ImporterBase::Base.failure_result("Setup error: #{e.message}", 0, {
            links_processed: 0,
            links_created: 0,
            sites_not_found: 0,
            sites_not_found_list: []
          })
        end

        def self.import_data(protected_area_class, story_map_link_class)
          links_processed = 0
          links_created = 0
          sites_not_found = 0
          sites_not_found_list = []
          soft_errors = []

          begin
            csv = CSV.read(STORY_MAP_LINK_LIST_SITES_CSV)
            csv.shift # remove headers

            csv.each do |row|
              # Wrap each row in its own transaction to prevent batch failure
              ActiveRecord::Base.transaction do
                links_processed += 1
                site_id = begin
                  Integer(row[0])
                rescue StandardError
                  false
                end

                if site_id == false
                  soft_errors << "Invalid site_id format: #{row[0]}"
                  next
                end

                protected_area = protected_area_class.find_by_wdpa_id(site_id)

                if protected_area.present?
                  link = story_map_link_class.where(protected_area: protected_area, link: row[1], link_type: row[2])
                    .first_or_create
                  links_created += 1 if link.persisted?
                else
                  sites_not_found += 1
                  sites_not_found_list << row[0]
                  Rails.logger.warn "Protected Area with site_id #{row[0]} doesn't exist"
                end
              end
            rescue StandardError => e
              soft_errors << "Failed to process row #{row[0]}: #{e.message}"
              Rails.logger.warn "Failed to process story map link row: #{e.message}"
            end

            Wdpa::Shared::ImporterBase::Base.success_result(links_processed, soft_errors, [], {
              links_processed: links_processed,
              links_created: links_created,
              sites_not_found: sites_not_found,
              sites_not_found_list: sites_not_found_list.uniq
            })
          rescue StandardError => e
            Rails.logger.error "Story map links import failed: #{e.message}"
            Wdpa::Shared::ImporterBase::Base.failure_result("Import failed: #{e.message}", 0, {
              links_processed: links_processed,
              links_created: links_created,
              sites_not_found: sites_not_found,
              sites_not_found_list: sites_not_found_list.uniq
            })
          end
        end
      end
    end
  end
end
