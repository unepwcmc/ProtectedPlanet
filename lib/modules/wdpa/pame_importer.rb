require 'csv'

module Wdpa::PameImporter
  PAME_EVALUATIONS = "#{Rails.root}/lib/data/seeds/pame_data-2019-08-30.csv".freeze

  def self.import (csv_file=nil)
    csv_file ||= PAME_EVALUATIONS
    PameEvaluation.import csv_file, "UTF-8"
  end
  
end
