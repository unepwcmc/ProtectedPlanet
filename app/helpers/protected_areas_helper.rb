module ProtectedAreasHelper
  def link_to_download protected_area, type
    url_for(
      controller: 'downloads',
      action: 'show',
      id: protected_area.countries.first.iso_3,
      type: type
    )
  end
end
