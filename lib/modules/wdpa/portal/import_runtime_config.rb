# frozen_string_literal: true

module Wdpa
  module Portal
    # Runtime config for importer execution, populated from args/env by Wdpa::Portal::Importer
    module ImportRuntimeConfig
      class << self
        attr_accessor :only, :skip, :sample, :label, :release_id, :checkpoints_enabled

        def reset!
          self.only = nil
          self.skip = nil
          self.sample = nil
          self.label = nil
          self.release_id = nil
          self.checkpoints_enabled = true
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
