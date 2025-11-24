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
    layers: [{url: MARINE_WDPA_MAP_SERVER_URL}],
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
    layers: [{url: OECM_POLY_LAYER_URL}, {url: OECM_POINT_LAYER_URL, isPoint: true}],
    color: OVERLAY_YELLOW,
    isShownByDefault: true,
    type: 'raster_data',
    queryString: MARINE_QUERY_STRING
  },
  {
    id: 'greenlist_terrestrial',
    isToggleable: false,
    layers: [{url: WDPA_POINT_LAYER_URL, isPoint: true}, {url: WDPA_POLY_LAYER_URL}],
    color: OVERLAY_GREEN,
    isShownByDefault: true,
    type: 'raster_data'
  },
  {
    id: 'greenlist_marine',
    isToggleable: false,
    layers: [{url: WDPA_POINT_LAYER_URL, isPoint: true}, {url: WDPA_POLY_LAYER_URL}],
    color: OVERLAY_BLUE,
    isShownByDefault: true,
    type: 'raster_data'
  }
].freeze

# Point layers first as this query is faster and stops on first successful query
ALL_SERVICES_FOR_POINT_QUERY = [
  { type: 'marine', url: MARINE_WDPA_POINT_LAYER_URL, isPoint: true },
  { type: 'wdpa', url: WDPA_POINT_LAYER_URL, isPoint: true },
  { type: 'oecm', url: OECM_POINT_LAYER_URL, isPoint: true },
  { type: 'marine', url: MARINE_WDPA_POLY_LAYER_URL, isPoint: false },
  { type: 'wdpa', url: WDPA_POLY_LAYER_URL, isPoint: false },
  { type: 'oecm', url: OECM_POLY_LAYER_URL, isPoint: false }
].freeze

# workaround for data-gis API issue with territories / PAs split by the int date line
# [<longitudinal padding west from IDL>, <longitudinal padding east from IDL>, <latitudinal padding>]
CUSTOM_DATE_LINE_PADDING = {
  # countries
  'FJI' => [5,5,2],
  'KIR' => [10,30,2],
  'NZL' => [20,5,5],
  'RUS' =>[150,10,5],
  'USA' => [10,120,5],
  'WLF' => [1,5,0.3]
}

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
    # Marine are subset of wdpa, so not required if wdpa already included
    ALL_SERVICES_FOR_POINT_QUERY.select { |s| s[:type] != 'marine' }
  end

  def marine_services_for_point_query
    marine_services = ALL_SERVICES_FOR_POINT_QUERY.select do |s|
      s[:type] == 'marine' || s[:type] == 'oecm'
    end

    marine_services.map do |s| 
      s[:type] == 'oecm' ? s.merge({ queryString: MARINE_WHERE_QUERY }) : s
    end
  end

  def oecm_services_for_point_query
    ALL_SERVICES_FOR_POINT_QUERY.select {|s| s[:type] == 'oecm' }
  end

  def wdpa_services_for_point_query
    ALL_SERVICES_FOR_POINT_QUERY.select {|s| s[:type] == 'wdpa' }
  end

  def country_extent_url (iso3)
    return {
      url: "https://data-gis.unep-wcmc.org/server/rest/services/GADM_EEZ_Layer/FeatureServer/0/query?where=iso_ter+%3D+%27#{iso3}%27&returnGeometry=false&returnExtentOnly=true&outSR=4326&f=pjson",
      padding: CUSTOM_DATE_LINE_PADDING[iso3] == nil ? [5,5,5] : CUSTOM_DATE_LINE_PADDING[iso3]
    }
  end

  def region_extent_url (name)
    {
      url: "https://data-gis.unep-wcmc.org/server/rest/services/EEZ_WVS/MapServer/0/query?where=geoandunep+%3D%27#{CGI.escape(name)}%27&text=&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&relationParam=&outFields=&returnGeometry=true&returnTrueCurves=false&maxAllowableOffset=&geometryPrecision=&outSR=4326&having=&returnIdsOnly=false&returnCountOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&gdbVersion=&historicMoment=&returnDistinctValues=false&resultOffset=&resultRecordCount=&queryByDistance=&returnExtentOnly=true&datumTransformation=&parameterValues=&rangeValues=&quantizationParameters=&featureEncoding=esriDefault&f=pjson",
      padding: [5,5,5]
    }
  end

  def site_ids_where_query site_ids
    # 'where=site_id+IN+%28' + site_ids.join('%2C+') + '%29'
    'where=wdpaid+IN+%28' + site_ids.join('%2C+') + '%29'
  end

  def greenlist_query_string site_ids
    '/query?' + site_ids_where_query(site_ids) + '&geometryType=esriGeometryEnvelope&returnGeometry=true&f=geojson'
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
