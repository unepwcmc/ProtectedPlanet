class Aichi11TargetSerializer < BaseSerializer
  PER_PAGE = 1.freeze

  def initialize(params={}, data=nil)
    super(Aichi11Target, params, data)
  end

  def serialize
    serialized_data = super
    serialized_data.merge(info_tooltips)
  end

  private

  def fields
    @model.column_names.reject do |attr|
      ['id', 'singleton_guard', 'created_at', 'updated_at'].include?(attr)
    end.map(&:to_sym)
  end

  def sort_by
    # This is only necessary to avoid an exception being thrown.
    # As there's only one record, sorting is not really necessary.
    super || 'importance_marine'
  end

  def order
    super || 'desc'
  end

  def per_page_default
    PER_PAGE
  end

  INFO = {
    coverage: "Proportion of a country's terrestrial or marine area covered by protected areas. Statistics updated monthly. Source: WDPA (hyperlink to PP) (UNEP-WCMC & IUCN)",
    effectively_managed: "Proportion of a country's terrestrial or marine protected area network where management effectiveness evaluations have been reported as being undertaken. Statistics updated monthly. Source: WDPA and GD-PAME (hyperlink to PP) (UNEP-WCMC & IUCN)",
    representative: "TBD",
    well_connected: "Proportion to which a country's terrestrial protected area network is designed to promote connectivity (note: no connectivity dataset is yet available for marine protected areas). Statistics updated [TODO]. Source: <a href='https://dopa.jrc.ec.europa.eu/en' target='_blank'>DOPA</a> (EU Joint Research Centre)",
    importance: "The average proportion of a country's terrestrial and marine key biodiversity areas that are covered with protected areas. Statistics updated [TODO]. Source: Birdlife (hyperlink to TODO) (EU Joint Research Centre)"
  }.freeze

  def info_tooltips
    { info_tooltips: INFO }
  end
end
