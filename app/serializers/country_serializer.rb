class CountrySerializer < BaseSerializer
  def initialize(data = nil)
    super(Country, data)
  end

  private

  def fields
    [:name, :iso_3]
  end
end
