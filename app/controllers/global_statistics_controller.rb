class GlobalStatisticsController < ApplicationController
  def show
    send_file filename, type: 'text/csv', disposition: 'attachment'
  end

  private

  def filename
    directory = "#{Rails.root}/lib/data/seeds/"
    global_statistics_csvs = Dir.glob("#{directory}/global_statistics*")
    latest_global_statistics_file = global_statistics_csvs.sort.last
    latest_global_statistics_file
  end
end
