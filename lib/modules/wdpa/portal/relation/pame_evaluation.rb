# frozen_string_literal: true

module Wdpa
  module Portal
    module Relation
      class PameEvaluation
        def initialize(current_attributes)
          @current_attributes = current_attributes
        end

        def create_models
          resolve_main_table_relations
          resolve_associated_table_relations

          # Relation callbacks are currently handled in resolve_* methods above.
          # Uncomment this loop if we re-enable per-key relation methods.
          # @current_attributes.each do |key, value|
          #   @current_attributes[key] = send(key, value) if respond_to?(key, true)
          # end

          @current_attributes
        end

        private
        
        def resolve_main_table_relations
          site_id = @current_attributes['site_id']
          site_pid = @current_attributes['site_pid'].presence || site_id&.to_s || nil
          @current_attributes['site_pid'] = site_pid

          protected_area_parcel = Staging::ProtectedAreaParcel.find_by(site_id: site_id, site_pid: site_pid) || nil
          protected_area = (protected_area_parcel ? nil : Staging::ProtectedArea.find_by_site_id(site_id)) || nil

          @current_attributes['protected_area'] = protected_area
          @current_attributes['protected_area_parcel'] = protected_area_parcel
          @current_attributes['name'] = protected_area_parcel&.name&.presence || protected_area&.name&.presence
        end

        def resolve_associated_table_relations
          @current_attributes['pame_method'] = @current_attributes['method'] ? PameMethod.find_or_create_by!(name: @current_attributes['method']) : nil 
          @current_attributes['pame_source'] = @current_attributes['eff_metaid'] ? Staging::PameSource.find_by(id: @current_attributes['eff_metaid']) : nil
        end

        # As we currently have method and eff_metaid in the main PAME table
        # so we uses resolve_associated_table_relations to deal with associated tables 
        # Once the method and eff_metaid are moved to the associated tables
        # then we can remove resolve_associated_table_relations and use the following methods instead

        # def pame_method(value)
        #   value.present? ? PameMethod.find_or_create_by!(name: value) : nil
        # end

        # def pame_source(value)
        #   value.present? ? Staging::PameSource.find_by(id: value) : nil
        # end
      end
    end
  end
end
