class GlobalStatisticsController < ApplicationController
  def download
    send_data GlobalStatistic.download_csv, type: 'text/csv', disposition: 'attachment',
      filename: GlobalStatistic.download_csv_filename
  end
end
