module RelatableProtectedAreas
  extend ActiveSupport::Concern

  # Accepts a block which allows any scopes defined for ProtectedArea to be applied
  # as protected_areas is an ActiveRecord collection
  #
  # e.g.
  # Country.first.related_protected_areas(limit: 3) do |protected_areas|
  #   protected_areas.without_geometry
  # end
  def related_protected_areas(limit: nil)
    protected_areas.yield_self do |protected_areas|
      block_given? ? yield(protected_areas) : protected_areas
    end.limit(limit).order(:name)
  end

  def related_protected_areas_without_geometry(limit: nil)
    protected_areas.without_geometry.yield_self do |protected_areas|
      block_given? ? yield(protected_areas) : protected_areas
    end.limit(limit).order(:name)
  end
end
