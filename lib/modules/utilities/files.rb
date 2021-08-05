# frozen_string_literal: true

module Utilities
  module Files
    #
    # Get the latest file based on a date within the filename from a directory using a glob
    #
    # E.g files:
    #
    #    <project>/foo/bar/baz_file_2021-04-01.csv
    #    <project>/foo/bar/baz_file_2021-05-01.csv
    #    <project>/foo/bar/baz_file_2021-06-01.csv
    #    <project>/foo/bar/baz_file_2021-07-01.csv
    #    <project>/foo/bar/baz_file_2021-08-01.csv
    #
    # If we want to automatically detect the latest file "baz_file_2021-08-01.csv",
    # we will use the following glob:
    #
    # "foo/bar/baz_file_*.csv"
    #
    # The file returned will be the absolute path to the latest file.
    def self.latest_file_by_glob(glob)
      Dir.glob(Rails.root.join(glob)).max_by do |file|
        Date.parse(file)
      end
    end
  end
end
