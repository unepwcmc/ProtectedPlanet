class HistoricWdpaController < ApplicationController
  def index
    wdpa_releases = HistoricWdpaRelease.all.order(:year, :month).as_json

    wdpa_releases.each do |release|
      release['name'] = "#{release['year']} - #{Date::MONTHNAMES[release['month']]}"
    end

    @wdpa_releases = wdpa_releases
    
    render cms_page: '/historic-versions-of-the-wdpa'
  end
end