# frozen_string_literal: true

module Wdpa
  module Portal
    module Importers
      class Source < Base
        def self.perform_import
          adapter = Wdpa::Portal::Adapters::ImportViewsAdapter.new
          relation = adapter.sources_relation

          process_with_errors(relation) do |source_attributes|
            standardised_attributes = Wdpa::Portal::Utils::ColumnMapper.map_portal_sources_to_pp(source_attributes)
            Staging::Source.create!(standardised_attributes)
            { count: 1, soft_errors: [] }
          end
        end
      end
    end
  end
end
