class GlobalStatisticsController < ApplicationController
  def download
    send_file GlobalStatistic.latest_csv, type: 'text/csv', disposition: 'attachment'
  end
end
