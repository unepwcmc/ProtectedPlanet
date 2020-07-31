OVERLAYS = [
  {
    id: 'terrestrial_wdpa',
    isToggleable: false,
    layers: ["https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_of_Protected_Areas/MapServer/tile/{z}/{y}/{x}"],
    color: "#38A800",
    isShownByDefault: true
  },
  {
    id: 'marine_wdpa',
    isToggleable: false,
    layers: ["https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_of_Protected_Areas/MapServer/tile/{z}/{y}/{x}"],
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

WDPA_FEATURE_SERVER_URL = 'https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_of_Protected_Areas/FeatureServer'
OECM_FEATURE_SERVER_LAYER_URL = 'https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_on_other_effective_area_based_conservation_measures/FeatureServer/0/'

SERVICES_FOR_POINT_QUERY = [
  { url: OECM_FEATURE_SERVER_LAYER_URL, isPoint: false },
  { url: WDPA_FEATURE_SERVER_URL + '/0/', isPoint: true },
  { url: WDPA_FEATURE_SERVER_URL + '/1/', isPoint: false }
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

  def services_for_point_query
    SERVICES_FOR_POINT_QUERY
  end

  def country_extent_url (iso3)
    {
      url: "https://data-gis.unep-wcmc.org/server/rest/services/AdministrativeUnits/GADM_EEZ_Layer/FeatureServer/0/query?where=GID_0+%3D+%27#{iso3}%27&returnGeometry=false&returnExtentOnly=true&outSR=4326&f=pjson", 
      padding: 5
    }
  end
  
  def region_extent_url (name)
    {
      url: "https://data-gis.unep-wcmc.org/server/rest/services/AdministrativeUnits/GADM_EEZ_Layer/FeatureServer/0/query?where=region+%3D+%27#{CGI.escape(name)}%27&returnGeometry=false&returnExtentOnly=true&outSR=4326&f=pjson", 
      padding: 5
    }
  end

  def map_search_types
    arr = []

    t('map.search_types').each do |id, translations|
      arr.push(translations.merge({id: id}))
    end

    arr
  end
end
