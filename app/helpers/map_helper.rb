OECM_FEATURE_SERVER_LAYER_URL = 'https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_on_other_effective_area_based_conservation_measures/FeatureServer/0'
OECM_MAP_SERVER_URL = 'https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_on_other_effective_area_based_conservation_measures/MapServer'
WDPA_FEATURE_SERVER_URL = 'https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_of_Protected_Areas/FeatureServer'
WDPA_MAP_SERVER_URL = 'https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_of_Protected_Areas/MapServer'
MARINE_WDPA_MAP_SERVER_URL = 'https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/WDPA_Marine_and_Coastal/MapServer'
TILE_PATH = "/tile/{z}/{y}/{x}"

MARINE_QUERY_STRING = '/query?where=marine+IN+%28%271%27%2C+%272%27%29&geometryType=esriGeometryEnvelope&returnGeometry=true&f=geojson'

OVERLAYS = [
  {
    id: 'terrestrial_wdpa',
    isToggleable: false,
    layers: [{url: WDPA_MAP_SERVER_URL}],
    color: "#38A800",
    isShownByDefault: true,
    type: 'raster_tile'
  },
  {
    id: 'marine_wdpa',
    isToggleable: false,
    layers: [{url: MARINE_WDPA_MAP_SERVER_URL }],
    color: "#004DA8",
    isShownByDefault: false,
    type: 'raster_tile'
  },
  {
    id: 'oecm',
    isToggleable: true,
    layers: [{url: OECM_MAP_SERVER_URL}],
    color: "#D9B143",
    isShownByDefault: true,
    type: 'raster_tile'
  },
  {
    id: 'oecm_marine',
    isToggleable: true,
    layers: [{url: OECM_MAP_SERVER_URL + '/0'}],
    color: "#D9B143",
    isShownByDefault: true,
    type: 'raster_data',
    queryString: MARINE_QUERY_STRING
  },
  {
    id: 'greenlist',
    isToggleable: false,
    layers: [{url: WDPA_MAP_SERVER_URL + '/0', isPoint: true}, {url: WDPA_MAP_SERVER_URL + '/1'}],
    color: "#004DA8",
    isShownByDefault: true,
    type: 'raster_data'
  },
  
].freeze

SERVICES_FOR_POINT_QUERY = [
  { url: OECM_FEATURE_SERVER_LAYER_URL, isPoint: false },
  { url: WDPA_FEATURE_SERVER_URL + '/0', isPoint: true },
  { url: WDPA_FEATURE_SERVER_URL + '/1', isPoint: false }
].freeze

module MapHelper
  def overlays (ids, options={})
    includedOverlays = OVERLAYS.select {|o| ids.include?(o[:id])}
  
    includedOverlays.map do |defaultOptions|
      customOptions = options[defaultOptions[:id].to_sym]
      defaultOptions.merge(customOptions || {})
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

  def greenlist_query_string wdpaids
    '/query?where=wdpaid+IN+%28' + wdpaids.join('%2C+') + '%29&geometryType=esriGeometryEnvelope&returnGeometry=true&f=geojson'
  end

  def map_search_types
    arr = []

    t('map.search_types').each do |id, translations|
      arr.push(translations.merge({id: id}))
    end

    arr
  end
end