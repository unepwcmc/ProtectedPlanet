# frozen_string_literal: true

module Utilities
  module Files
    # get the latest file based on a date within the filename from a directory using a glob
    def self.latest_file_by_glob(glob)
      Dir.glob(Rails.root.join(glob)).max_by do |file|
        Date.parse(file)
      end
    end
  end
end
