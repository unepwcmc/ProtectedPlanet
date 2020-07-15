OVERLAYS = [
  {
    id: 'terrestrial_wdpa',
    isToggleable: false,
    layers: ["https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_on_Protected_Areas/MapServer/tile/{z}/{y}/{x}"],
    color: "#38A800",
    isShownByDefault: true
  },
  {
    id: 'marine_wdpa',
    isToggleable: false,
    layers: ["https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_on_Protected_Areas/MapServer/tile/{z}/{y}/{x}"],
    color: "#004DA8",
    isShownByDefault: true
  },
  {
    id: 'oecm',
    isToggleable: true,
    layers: ["https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_on_other_effective_area_based_conservation_measures/MapServer/tile/{z}/{y}/{x}"],
    color: "#D9B143",
    isShownByDefault: true
  }
].freeze

module MapHelper
  def overlays (ids, options={})
    includedOverlays = OVERLAYS.select {|o| ids.include?(o[:id])}
  
    includedOverlays.map do |defaultOptions|
      overlayOptions = options[defaultOptions[:id].to_sym]

      overlayOptions.nil? ? defaultOptions : defaultOptions.merge(overlayOptions)
    end
  end

  def map_yml
    I18n.t('map')
  end
end
