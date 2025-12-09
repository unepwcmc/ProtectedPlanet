class DatabaseAreasPresenter
  include Concerns::AreasCards

  def initialize(cms_site)
    @cms_site = cms_site
  end

  def database_areas
    area_payload('databases')
  end
end