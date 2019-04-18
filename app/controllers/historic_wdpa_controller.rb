class HistoricWdpaController < ApplicationController
  def index
    @wdpa_releases = HistoricWdpaRelease.all

    render cms_page: '/historic-versions-of-the-wdpa'
  end
end