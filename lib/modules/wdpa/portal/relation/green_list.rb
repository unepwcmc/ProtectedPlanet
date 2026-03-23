# frozen_string_literal: true

module Wdpa
  module Portal
    module Relation
      class GreenList
        def initialize(mapped_attributes)
          @mapped_attributes = mapped_attributes
        end

        # Resolves PA/parcel from site_id/site_pid and returns attributes for GreenListStatus create.
        # Returns { pa: Staging::ProtectedArea | Staging::ProtectedAreaParcel, attributes_for_create: Hash }.
        # pa is nil if no matching PA/parcel found.
        def create_models
          site_id = @mapped_attributes['site_id']
          site_pid = @mapped_attributes['site_pid'].to_s.presence || site_id&.to_s

          pa = nil
          pa = Staging::ProtectedAreaParcel.find_by(site_id: site_id, site_pid: site_pid) if site_id.present?
          pa = Staging::ProtectedArea.find_by(site_id: site_id) if pa.blank? && site_id.present?

          remove_fields

          {
            pa: pa,
            attributes_for_create: @mapped_attributes
          }
        end

        private

        # Strip columns_not_for_create so @mapped_attributes holds only attributes for Staging::GreenListStatus.create!
        def remove_fields
          Wdpa::Portal::Utils::GreenListColumnMapper.columns_not_for_create.each do |column_name|
            @mapped_attributes.delete(column_name)
            @mapped_attributes.delete(column_name.to_sym)
          end
        end
      end
    end
  end
end
