class Wdpa::ParcelRelation
  def initialize(current_attributes)
    @current_attributes = current_attributes
  end

  def create(attribute, value)
    return send(attribute, value) if respond_to? attribute, true

    value
  end

  private

  def sub_locations(value)
    sub_locations = value.map { |iso| SubLocation.where(iso: iso).first }
    sub_locations.compact
  end

  def legal_status(value)
    LegalStatus.where(name: value).first_or_create
  end

  def iucn_category(value)
    IucnCategory.where(name: value).first
  end

  def governance(value)
    Governance.where(name: value).first
  end

  def management_authority(value)
    ManagementAuthority.where(name: value).first_or_create
  end

  def countries(value)
    countries = value.map { |iso_3| Country.select('id').where(iso_3: iso_3).first }
    countries.compact
  end

  def designation(value)
    jurisdiction = Jurisdiction.where(name: @current_attributes[:jurisdiction]).first
    Designation.where({
      name: value,
      jurisdiction: jurisdiction
    }).first_or_create
  end

  def no_take_status(value)
    NoTakeStatus.create({
      name: value,
      area: @current_attributes[:no_take_area]
    })
  end
end
