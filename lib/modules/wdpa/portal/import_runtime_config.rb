# frozen_string_literal: true

module Wdpa
  module Portal
    # Runtime config for importer execution, populated from args/env by Wdpa::Portal::Importer
    module ImportRuntimeConfig
      class << self
        attr_accessor :only, :skip, :sample, :label, :release_id, :checkpoints_enabled
        attr_reader :stats_source

        STATS_SOURCES = %w[db csv].freeze

        def reset!
          self.only = nil
          self.skip = nil
          self.sample = nil
          self.label = nil
          self.release_id = nil
          self.checkpoints_enabled = true
          @stats_source = 'csv'
        end

        def stats_source=(val)
          normalized = val.to_s.strip.downcase
          normalized = 'csv' if normalized.empty?
          unless STATS_SOURCES.include?(normalized)
            raise ArgumentError, "Invalid stats source '#{val}' (PP_STATS_SOURCE) — expected one of: #{STATS_SOURCES.join(', ')}"
          end

          @stats_source = normalized
        end

        def stats_from_db?
          stats_source == 'db'
        end

        def only_list
          normalize_list(only)
        end

        def skip_list
          normalize_list(skip)
        end

        def normalize_list(val)
          case val
          when nil then []
          when Array then val.map { |s| s.to_s.strip }.reject(&:empty?)
          else val.to_s.split(',').map { |s| s.strip }.reject(&:empty?)
          end
        end

        def sample_limit
          l = sample
          return nil if l.nil? || l.to_s.strip.empty?

          l.to_i > 0 ? l.to_i : nil
        end

        def checkpoints?
          checkpoints_enabled != false
        end
      end
    end
  end
end
