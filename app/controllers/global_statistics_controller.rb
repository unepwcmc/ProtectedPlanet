class GlobalStatisticsController < ApplicationController
  def show
    send_file GlobalStatistic.latest_csv, type: 'text/csv', disposition: 'attachment'
  end
end
