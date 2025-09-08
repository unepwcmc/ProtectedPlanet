# frozen_string_literal: true

module Wdpa
  module Portal
    module Importers
      class Base
        def self.import_staging
          result = perform_import
          standard_result(
            result[:imported_count] || 0,
            result[:soft_errors] || [],
            result[:hard_errors] || [],
            result[:additional_fields] || {}
          )
        rescue StandardError => e
          failure_result("Setup error: #{e.message}")
        end

        # Helper methods for error handling
        def self.empty_result(count_key = :imported_count)
          { count_key => 0, soft_errors: [], hard_errors: [] }
        end

        def self.success_result(count_key = :imported_count, soft_errors = [], hard_errors = [])
          {
            success: hard_errors.empty?,
            count_key => (count_key == :imported_count ? 0 : nil),
            soft_errors: soft_errors,
            hard_errors: hard_errors
          }
        end

        def self.failure_result(error_message, count_key = :imported_count)
          {
            success: false,
            count_key => (count_key == :imported_count ? 0 : nil),
            soft_errors: [],
            hard_errors: [error_message]
          }
        end

        def self.process_with_errors(collection, &block)
          soft_errors = []
          imported_count = 0

          collection.each do |item|
            result = block.call(item)
            imported_count += result[:count] if result[:count]
            soft_errors.concat(result[:soft_errors]) if result[:soft_errors]
          rescue StandardError => e
            soft_errors << "Row error: #{e.message}"
            Rails.logger.warn "Row processing failed: #{e.message}"
          end

          { imported_count: imported_count, soft_errors: soft_errors }
        end

        def self.merge_errors(results)
          soft_errors = []
          hard_errors = []

          results.each do |result|
            soft_errors.concat(result[:soft_errors] || [])
            hard_errors.concat(result[:hard_errors] || [])
          end

          { soft_errors: soft_errors, hard_errors: hard_errors }
        end

        def self.standard_result(imported_count, soft_errors = [], hard_errors = [], additional_fields = {})
          {
            success: hard_errors.empty?,
            imported_count: imported_count,
            soft_errors: soft_errors,
            hard_errors: hard_errors
          }.merge(additional_fields)
        end

        # Override this method in subclasses
        def self.perform_import
          raise NotImplementedError, 'Subclasses must implement perform_import'
        end
      end
    end
  end
end
