class HistoricWdpaRelease < ActiveRecord::Base
  self.table_name = "comfy_cms_historic_wdpa_releases"

  validates :year,
    presence: true,
    allow_nil: false
  validates :month,
    presence: true,
    allow_nil: false
  validates :url,
    presence: true,
    length: {maximum: 255},
    allow_nil: false
end