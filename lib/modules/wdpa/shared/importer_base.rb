# frozen_string_literal: true

module Wdpa
  module Shared
    module ImporterBase
      # Base class for all importers with shared helper methods
      # Helper methods for error handling - shared across all importers
      class Base
        def self.success_result(count_key = :imported_count, soft_errors = [], hard_errors = [], additional_fields = {})
          {
            success: hard_errors.empty?,
            count_key => (count_key == :imported_count ? 0 : nil),
            soft_errors: soft_errors,
            hard_errors: hard_errors
          }.merge(additional_fields)
        end

        def self.failure_result(error_message, count_key = :imported_count, additional_fields = {})
          {
            success: false,
            count_key => (count_key == :imported_count ? 0 : nil),
            soft_errors: [],
            hard_errors: [error_message]
          }.merge(additional_fields)
        end
      end
    end
  end
end
