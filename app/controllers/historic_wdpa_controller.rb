class HistoricWdpaController < ApplicationController
  def index
    @wdpa_releases = [
      { id: 1, name: '2015 - January', url: 'https://wdpa.s3.amazonaws.com/2015/WDPA_Jan2015_Public.zip' },
      { id: 1, name: '2015 - February', url: '' },
      { id: 2, name: '2016 - January', url: '' },
      { id: 3, name: '2017 - January', url: '' },
      { id: 3, name: '2017 - March', url: '' },
      { id: 4, name: '2018 - January', url: '' },
      { id: 5, name: '2019 - January', url: '' },
    ]

    render cms_page: '/historic-versions-of-the-wdpa'
  end
end