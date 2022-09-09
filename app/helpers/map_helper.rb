OECM_FEATURE_SERVER_LAYER_URL = 'https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_on_other_effective_area_based_conservation_measures/FeatureServer/0'
OECM_MAP_SERVER_URL = 'https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_on_other_effective_area_based_conservation_measures/MapServer'
OECM_POINT_LAYER_URL = OECM_MAP_SERVER_URL + '/0'
OECM_POLY_LAYER_URL = OECM_MAP_SERVER_URL + '/1'
WDPA_FEATURE_SERVER_URL = 'https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_of_Protected_Areas/FeatureServer'
WDPA_MAP_SERVER_URL = 'https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_of_Protected_Areas/MapServer'
WDPA_POINT_LAYER_URL = WDPA_MAP_SERVER_URL + '/0'
WDPA_POLY_LAYER_URL = WDPA_MAP_SERVER_URL + '/1'
MARINE_WDPA_MAP_SERVER_URL = 'https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/WDPA_Marine_and_Coastal/MapServer'
MARINE_WDPA_POINT_LAYER_URL = MARINE_WDPA_MAP_SERVER_URL + '/0'
MARINE_WDPA_POLY_LAYER_URL = MARINE_WDPA_MAP_SERVER_URL + '/1'

TILE_PATH = "/tile/{z}/{y}/{x}"
MARINE_WHERE_QUERY = 'where=marine+IN+%28%271%27%2C+%272%27%29'
MARINE_QUERY_STRING = '/query?' + MARINE_WHERE_QUERY + '&geometryType=esriGeometryEnvelope&returnGeometry=true&f=geojson'

OVERLAY_GREEN = "#38A800"
OVERLAY_BLUE = "#004DA8"
OVERLAY_YELLOW = "#D9B143"

OVERLAYS = [
  {
    id: 'terrestrial_wdpa',
    isToggleable: false,
    layers: [{url: WDPA_MAP_SERVER_URL}],
    color: OVERLAY_GREEN,
    isShownByDefault: true,
    type: 'raster_tile'
  },
  {
    id: 'individual_site',
    isToggleable: false,
    layers: [{url: WDPA_POINT_LAYER_URL, isPoint: true}, {url: WDPA_POLY_LAYER_URL}],
    color: OVERLAY_GREEN,
    isShownByDefault: true,
    type: 'raster_data'
  },
  {
    id: 'marine_wdpa',
    isToggleable: false,
    layers: [{url: MARINE_WDPA_MAP_SERVER_URL }],
    color: OVERLAY_BLUE,
    isShownByDefault: false,
    type: 'raster_tile'
  },
  {
    id: 'oecm',
    isToggleable: true,
    layers: [{url: OECM_MAP_SERVER_URL}],
    color: OVERLAY_YELLOW,
    isShownByDefault: true,
    type: 'raster_tile'
  },
  {
    id: 'oecm_marine',
    isToggleable: true,
    layers: [{url: OECM_MAP_SERVER_URL + '/0'}],
    color: OVERLAY_YELLOW,
    isShownByDefault: true,
    type: 'raster_data',
    queryString: MARINE_QUERY_STRING
  },
  {
    id: 'greenlist_terrestrial',
    isToggleable: false,
    layers: [{url: WDPA_MAP_SERVER_URL + '/0', isPoint: true}, {url: WDPA_MAP_SERVER_URL + '/1'}],
    color: OVERLAY_GREEN,
    isShownByDefault: true,
    type: 'raster_data'
  },
  {
    id: 'greenlist_marine',
    isToggleable: false,
    layers: [{url: WDPA_MAP_SERVER_URL + '/0', isPoint: true}, {url: WDPA_MAP_SERVER_URL + '/1'}],
    color: OVERLAY_BLUE,
    isShownByDefault: true,
    type: 'raster_data'
  }
].freeze

ALL_SERVICES_FOR_POINT_QUERY = [
  { url: WDPA_POLY_LAYER_URL, isPoint: false },
  { url: WDPA_POINT_LAYER_URL, isPoint: true },
  { url: OECM_POINT_LAYER_URL, isPoint: true },
  { url: OECM_POLY_LAYER_URL, isPoint: false }
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

  def all_services_for_point_query
    ALL_SERVICES_FOR_POINT_QUERY
  end

  def country_extent_url (iso3)
    {
      url: "https://data-gis.unep-wcmc.org/server/rest/services/GADM_EEZ_Layer/FeatureServer/0/query?where=iso_ter+%3D+%27#{iso3}%27&returnGeometry=false&returnExtentOnly=true&outSR=4326&f=pjson",
      padding: 5
    }
  end

  def region_extent_url (name)
    {
      url: "https://data-gis.unep-wcmc.org/server/rest/services/EEZ_WVS/MapServer/0/query?where=geoandunep+%3D%27#{CGI.escape(name)}%27&text=&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&relationParam=&outFields=&returnGeometry=true&returnTrueCurves=false&maxAllowableOffset=&geometryPrecision=&outSR=4326&having=&returnIdsOnly=false&returnCountOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&gdbVersion=&historicMoment=&returnDistinctValues=false&resultOffset=&resultRecordCount=&queryByDistance=&returnExtentOnly=true&datumTransformation=&parameterValues=&rangeValues=&quantizationParameters=&featureEncoding=esriDefault&f=pjson",
      padding: 5
    }
  end

  def wdpaid_where_query wdpaids
    'where=wdpaid+IN+%28' + wdpaids.join('%2C+') + '%29'
  end

  def greenlist_query_string wdpaids
    '/query?' + wdpaid_where_query(wdpaids) + '&geometryType=esriGeometryEnvelope&returnGeometry=true&f=geojson'
  end

  def map_search_types
    arr = []

    t('map.search_types').each do |id, translations|
      arr.push(translations.merge({id: id}))
    end

    arr
  end

  def map_legend
    [
      { theme: 'theme--terrestrial', title: I18n.t('map.overlays.terrestrial_wdpa.title') },
      { theme: 'theme--marine', title: I18n.t('map.overlays.marine_wdpa.title') },
      { theme: 'theme--oecm', title: I18n.t('map.overlays.oecm.title') }
    ]
  end
end
