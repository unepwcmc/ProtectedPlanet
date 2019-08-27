class CountrySerializer < BaseSerializer
  PER_PAGE = 15.freeze

  def initialize(params={}, data = nil)
    super(Country, params, data)
  end

  private

  def fields
    [:name, :iso_3]
  end

  def relations
    {
      country_statistic: [
        :percentage_pa_land_cover, :percentage_pa_marine_cover,
        :well_connected, :importance
      ],
      pame_statistic: [:pame_percentage_pa_land_cover, :pame_percentage_pa_marine_cover]
    }
  end

  def sort_by
    super || 'well_connected'
  end

  def order
    super || 'desc'
  end

  def per_page_default
    PER_PAGE
  end
end
