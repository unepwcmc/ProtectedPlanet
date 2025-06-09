<template>
  <div class="v-map">
    <div :id="containerId" class="map__mapbox" />
    <v-map-baselayer-controls v-if="controlsOptions.showBaselayerControls" :baselayers="baselayers" />
    <br />
    <div class="map__mapbox" id="map"></div>
    <div id="message">Without moving your mouse, click on overlapping sites to cycle through them.</div>
    <div id="popup"></div>
    <div class="map__mapbox" id="worldMap"></div>
    <div id="message">Without moving your mouse, click on overlapping sites to cycle through them.</div>
    <div id="popupWorldMap"></div>

  </div>
</template>

<script>
import { containsObjectWithId } from '../../helpers/array-helpers'
import { executeAfterCondition } from '../../helpers/timing-helpers'
import {
  BASELAYERS_DEFAULT,
  CONTROLS_OPTIONS_DEFAULT,
  EMPTY_OPTIONS,
  MAP_OPTIONS_DEFAULT,
  RTL_TEXT_PLUGIN_URL
} from './default-options'

import VMapBaselayerControls from './VMapBaselayerControls'
import mixinAddLayers from './mixins/mixin-add-layers'
import mixinControls from './mixins/mixin-controls'
import mixinLayers from './mixins/mixin-layers'
import mixinPaPopup from './mixins/mixin-pa-popup'
import mixinBoundingBox from './mixins/mixin-bounding-box'

export default {
  name: 'VMap',

  components: { VMapBaselayerControls },

  mixins: [
    mixinAddLayers,
    mixinBoundingBox,
    mixinControls,
    mixinPaPopup,
    mixinLayers
  ],

  props: {
    options: {
      type: Object,
      default: () => EMPTY_OPTIONS
    }
  },

  data() {
    return {
      accessToken: process.env.MAPBOX_ACCESS_TOKEN,
      containerId: MAP_OPTIONS_DEFAULT.container,
      map: {},
    }
  },

  computed: {
    baselayers() {
      return this.options.baselayers || BASELAYERS_DEFAULT
    },

    controlsOptions() {
      return {
        ...CONTROLS_OPTIONS_DEFAULT,
        ...this.options.controls
      }
    },

    mapOptions() {
      const options = {
        ...MAP_OPTIONS_DEFAULT,
        ...this.options.map,
        style: this.baselayers[0].style,
      }

      if (this.initBounds) {
        options.bounds = this.initBounds
      }

      return options
    },

    selectedBaselayer() {
      return this.$store.state.map.selectedBaselayer
    },

    visibleLayers() {
      return this.$store.state.map.visibleLayers
    }
  },

  watch: {
    visibleLayers(newLayers, oldLayers) {
      const layersToHide = oldLayers.filter(oL =>
        !containsObjectWithId(newLayers, oL.id)
      )

      this.hideLayers(layersToHide)
      this.showLayers(newLayers)
    },

    selectedBaselayer() {
      this.executeAfterStyleLoad(() => {
        this.map.setStyle(this.selectedBaselayer.style)
        this.showLayers(this.visibleLayers)
      })
    }
  },

  mounted() {
    this.initBoundingBoxAndMap()
  },

  methods: {
    initMap() {
      /* eslint-disable no-undef */
      mapboxgl.accessToken = this.accessToken
      // Add support for RTL languages
      mapboxgl.setRTLTextPlugin(
        RTL_TEXT_PLUGIN_URL,
        null,
        true // Lazy loading
      )
      this.map = new mapboxgl.Map(this.mapOptions)
      this.addControls()
      this.addEventHandlersToMap()
    },

    addEventHandlersToMap() {
      this.$eventHub.$on('map:resize', () => this.map.resize())

      this.map.on('style.load', () => {
        this.setFirstForegroundLayerId()
      })

      if (this.onClick) {
        this.map.on('click', e => {
          if (e.originalEvent.detail === 1) {
            this.onClick(e)
          }
        })
      }
    },

    showLayers(layers) {
      this.executeAfterStyleLoad(() => {
        layers.forEach(l => this.showLayer(l))
      })
    },

    showLayer(layer) {
      const mapboxLayer = this.map.getLayer(layer.id)
      const isVisible = mapboxLayer && mapboxLayer.visibility === 'visible'

      if (!mapboxLayer) {
        this.addLayerBeneathBoundariesAndLabels(layer)
      } else if (!isVisible) {
        this.setLayerVisibility(layer, true)
      }
    },

    addLayerBeneathBoundariesAndLabels(layer) {
      executeAfterCondition(
        () => this.firstForegroundLayerId,
        () => { this.addLayer(layer) },
        10
      )
    },

    addLayer(layer) {
      if (layer.type === 'raster_tile') {
        this.addRasterTileLayer(layer)
      } else if (layer.type === 'raster_data') {
        this.addRasterDataLayer(layer)
      }
    },

    hideLayers(layers) {
      this.setLayerVisibilities(layers, false)
    },

    setLayerVisibilities(layers, isVisible) {
      layers.forEach(l => {
        this.setLayerVisibility(l, isVisible)
      })
    },

    setLayerVisibility(layer, isVisible) {
      const layerId = layer.id
      const visibility = isVisible ? 'visible' : 'none'

      if (this.map.getLayer(layerId)) {
        this.map.setLayoutProperty(layerId, 'visibility', visibility)
      }
    },
    wdpaMap() {
      const MAPTILER_KEY = 'get_your_own_OpIi9ZULNHzrESv6T2vL';
      const map = new maplibregl.Map({
        container: 'map',
        style: `https://api.maptiler.com/maps/basic-v2/style.json?key=${MAPTILER_KEY}`,
        center: [0, 20],
        zoom: 2
      });

      let lastClickPoint = null;
      let overlappingFeatures = [];
      let currentIndex = 0;

      map.on('load', () => {
        // https://data-gis.unep-wcmc.org/server/rest/services/Hosted/TargetTrackerCountriesTerritories/VectorTileServer/tile/1/1/1.pbf

        map.addSource('protected_areas', {
          type: 'vector',
          tiles: [
            'https://vectortileservices5.arcgis.com/Mj0hjvkNtV7NRhA7/arcgis/rest/services/WDPA_World_Database_of_Protected_Areas_VTS/VectorTileServer/tile/{z}/{y}/{x}.pbf'
          ],
          promoteId: 'wdpaid'
        });

        map.addLayer({
          id: 'protected_areas',
          source: 'protected_areas',
          'source-layer': 'WDPA_poly_Latest',
          type: 'fill',
          paint: {
            'fill-color': [
              'match',
              ['get', 'marine'],
              '0', '#4CAF50',     // Terrestrial - Green
              '1', '#0077BE',     // Partly Marine - Orange
              '2', '#0077BE',     // Marine - Blue
              '#cccccc'         // Default / unknown
            ],
            'fill-opacity': 0.5
          }
        });


        // Hover highlight layer
        map.addSource('hovered-feature', {
          type: 'geojson',
          data: { type: 'FeatureCollection', features: [] }
        });

        map.addLayer({
          id: 'hover-fill',
          type: 'fill',
          source: 'hovered-feature',
          paint: {
            'fill-color': '#ff9248',
            'fill-opacity': 0.4
          }
        });

        map.addLayer({
          id: 'hover-outline',
          type: 'line',
          source: 'hovered-feature',
          paint: {
            'line-color': '#ff9248',
            'line-width': 2
          }
        });

        // Selected (clicked) feature highlight
        map.addSource('hovered-pa', {
          type: 'geojson',
          data: { type: 'FeatureCollection', features: [] }
        });

        map.addLayer({
          id: 'click-fill',
          type: 'fill',
          source: 'hovered-pa',
          paint: {
            'fill-color': '#154406',
            'fill-opacity': 0.6
          }
        });

        map.addLayer({
          id: 'click-outline',
          type: 'line',
          source: 'hovered-pa',
          paint: {
            'line-color': '#154406',
            'line-width': 3
          }
        });

        // Hover effect
        map.on('mousemove', 'protected_areas', function (e) {
          map.getCanvas().style.cursor = 'pointer';
          const feature = e.features?.[0];
          if (feature) {
            map.getSource('hovered-feature').setData({
              type: 'FeatureCollection',
              features: [feature]
            });
          }
        });

        map.on('mouseleave', 'protected_areas', function () {
          map.getCanvas().style.cursor = '';
          map.getSource('hovered-feature').setData({
            type: 'FeatureCollection',
            features: []
          });
        });

        // Click to cycle through overlapping features
        map.on('click', 'protected_areas', function (e) {
          const clickPoint = `${e.point.x},${e.point.y}`;
          const features = map.queryRenderedFeatures(e.point, {
            layers: ['protected_areas']
          });

          if (!features.length) return;

          if (clickPoint === lastClickPoint) {
            currentIndex = (currentIndex + 1) % features.length;
          } else {
            lastClickPoint = clickPoint;
            overlappingFeatures = features;
            currentIndex = 0;
          }

          const selected = overlappingFeatures[currentIndex];

          map.getSource('hovered-pa').setData({
            type: 'FeatureCollection',
            features: [selected]
          });

          const id = selected.properties?.wdpaid || selected.id;
          const pid = selected.properties?.wdpa_pid || selected.pid;
          const name = selected.properties?.name || 'Unnamed';
          const marineCode = selected.properties?.marine;
          const marine = marineCode === 0 || marineCode === '0'
            ? 'Terrestrial'
            : marineCode === 1 || marineCode === '1'
              ? 'Coastal'
              : marineCode === 2 || marineCode === '2'
                ? 'Marine'
                : 'Unknown';

          const popup = document.getElementById('popup');
          popup.innerHTML = `
      <h3><a href="https://www.protectedplanet.net/${id}" target="_blank" rel="noopener noreferrer">${name}</a></h3>
      <p><strong>Site ID:</strong> ${id}</p>
      <p><strong>Parcel ID:</strong> ${pid}</p>
      <p><strong>Realm:</strong> ${marine}</p>
      <p><em>Showing ${currentIndex + 1} of ${features.length}</em></p>
    `;
          popup.style.display = 'block';

          const msg = document.getElementById('message');
          if (features.length > 1) {
            msg.innerHTML = `Click again to cycle through ${features.length} overlapping features. Showing ${currentIndex + 1}.`;
          } else {
            msg.innerHTML = `Showing 1 of 1 feature.`;
          }
        });

        // Global click handler to clear selection when clicking empty space
        map.on('click', function (e) {
          const features = map.queryRenderedFeatures(e.point, {
            layers: ['protected_areas']
          });

          if (!features.length) {
            map.getSource('hovered-pa').setData({
              type: 'FeatureCollection',
              features: []
            });

            lastClickPoint = null;
            overlappingFeatures = [];
            currentIndex = 0;

            const msg = document.getElementById('message');
            msg.innerHTML = `No feature selected. Click a site to begin.`;

            const popup = document.getElementById('popup');
            popup.style.display = 'none';
            popup.innerHTML = '';
          }
        });
      });
    },
    worldMap() {
      const MAPTILER_KEY = 'get_your_own_OpIi9ZULNHzrESv6T2vL';
      const map = new maplibregl.Map({
        container: 'worldMap',
        style: `https://api.maptiler.com/maps/basic-v2/style.json?key=${MAPTILER_KEY}`,
        center: [0, 20],
        zoom: 2
      });

      let lastClickPoint = null;
      let overlappingFeatures = [];
      let currentIndex = 0;
      const layers =  [
    {
      "id": "CountryPolygons/ABW; Aruba; Aruba (Neth.); NLD; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        0],
      "layout": {

      },
      "paint": {
        "fill-color": "#FED0BD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/AFG; Afghanistan; Afghanistan; AFG; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        1],
      "layout": {

      },
      "paint": {
        "fill-color": "#D5C6FE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/AGO; Angola; Angola; AGO; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        2],
      "layout": {

      },
      "paint": {
        "fill-color": "#FFCEF3",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/AIA; Anguilla; Anguilla *; GBR; Non-Self Governing Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        3],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDF1BB",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ALA; Åland Islands; Åland Islands; FIN; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        4],
      "layout": {

      },
      "paint": {
        "fill-color": "#C6FEE2",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ALB; Albania; Albania; ALB; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        5],
      "layout": {

      },
      "paint": {
        "fill-color": "#FECAE2",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/AND; Andorra; Andorra; AND; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        6],
      "layout": {

      },
      "paint": {
        "fill-color": "#C9FDDC",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ARE; United Arab Emirates; United Arab Emirates; ARE; Member State; West Asia",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        7],
      "layout": {

      },
      "paint": {
        "fill-color": "#F8FEC3",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ARG; Argentina; Argentina; ARG; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        8],
      "layout": {

      },
      "paint": {
        "fill-color": "#F2FDB3",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ARM; Armenia; Armenia; ARM; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        9],
      "layout": {

      },
      "paint": {
        "fill-color": "#F1FED4",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ASM; American Samoa; American Samoa *; USA; Non-Self Governing Territory; North America",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        10],
      "layout": {

      },
      "paint": {
        "fill-color": "#C1F0FE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ATA; Antarctica; Antarctica; ATA; Antarctica; Antarctica",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        11],
      "layout": {

      },
      "paint": {
        "fill-color": "#FCF5CD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ATF; Bassas da India; Bassas da India (Fr.); FRA; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        12],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDD1EA",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ATF; Europa Island; Europa Island (Fr.); FRA; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        13],
      "layout": {

      },
      "paint": {
        "fill-color": "#BEFFD8",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ATF; French Southern Territories; French Southern Territories (Fr.); FRA; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        14],
      "layout": {

      },
      "paint": {
        "fill-color": "#F9C3FE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ATF; Glorioso Islands; Glorioso Islands (Fr.); FRA; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        15],
      "layout": {

      },
      "paint": {
        "fill-color": "#B1C9FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ATF; Juan de Nova Island; Juan de Nova Island (Fr.); FRA; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        16],
      "layout": {

      },
      "paint": {
        "fill-color": "#B5EEFD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ATF; Tromelin Island; Tromelin Island (Fr.); FRA; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        17],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDD5D1",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ATG; Antigua and Barbuda; Antigua and Barbuda; ATG; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        18],
      "layout": {

      },
      "paint": {
        "fill-color": "#CEFFB8",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/AUS; Ashmore and Cartier Islands; Ashmore & Cartier Is. (Aust.); AUS; Territory; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        19],
      "layout": {

      },
      "paint": {
        "fill-color": "#F8FDCD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/AUS; Australia; Australia; AUS; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        20],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEC1CB",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/AUT; Austria; Austria; AUT; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        21],
      "layout": {

      },
      "paint": {
        "fill-color": "#CBDAFD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/AZE; Azerbaijan; Azerbaijan; AZE; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        22],
      "layout": {

      },
      "paint": {
        "fill-color": "#BAFEFA",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/BDI; Burundi; Burundi; BDI; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        23],
      "layout": {

      },
      "paint": {
        "fill-color": "#D3B3FE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/BEL; Belgium; Belgium; BEL; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        24],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEF3CA",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/BEN; Benin; Benin; BEN; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        25],
      "layout": {

      },
      "paint": {
        "fill-color": "#EAFDD3",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/BES; Bonaire; Bonaire (Neth.); NLD; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        26],
      "layout": {

      },
      "paint": {
        "fill-color": "#EEFEC4",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/BES; Saba; Saba (Neth.); NLD; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        27],
      "layout": {

      },
      "paint": {
        "fill-color": "#C8C4FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/BES; Sint Eustatius; Sint Eustatius (Neth.); NLD; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        28],
      "layout": {

      },
      "paint": {
        "fill-color": "#D1FEC9",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/BFA; Burkina Faso; Burkina Faso; BFA; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        29],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDD4D2",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/BGD; Bangladesh; Bangladesh; BGD; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        30],
      "layout": {

      },
      "paint": {
        "fill-color": "#DFD1FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/BGR; Bulgaria; Bulgaria; BGR; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        31],
      "layout": {

      },
      "paint": {
        "fill-color": "#F5FFBF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/BHR; Bahrain; Bahrain; BHR; Member State; West Asia",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        32],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEECCE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/BHS; Bahamas; Bahamas; BHS; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        33],
      "layout": {

      },
      "paint": {
        "fill-color": "#DDCCFD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/BIH; Bosnia and Herzegovina; Bosnia and Herzegovina; BIH; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        34],
      "layout": {

      },
      "paint": {
        "fill-color": "#FECBF3",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/BLM; Saint Barthélemy; Saint Barthélemy (Fr.); FRA; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        35],
      "layout": {

      },
      "paint": {
        "fill-color": "#EAFEC4",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/BLR; Belarus; Belarus; BLR; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        36],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDC7EE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/BLZ; Belize; Belize; BLZ; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        37],
      "layout": {

      },
      "paint": {
        "fill-color": "#EDD0FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/BMU; Bermuda; Bermuda *; GBR; Non-Self Governing Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        38],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEC5F0",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/BOL; Bolivia (Plurinational State of); Bolivia (Plurinational State of); BOL; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        39],
      "layout": {

      },
      "paint": {
        "fill-color": "#E4FFB6",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/BRA; Brazil; Brazil; BRA; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        40],
      "layout": {

      },
      "paint": {
        "fill-color": "#F8FEB8",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/BRB; Barbados; Barbados; BRB; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        41],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEE5D5",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/BRN; Brunei Darussalam; Brunei Darussalam; BRN; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        42],
      "layout": {

      },
      "paint": {
        "fill-color": "#FBFDC7",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/BTN; Bhutan; Bhutan; BTN; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        43],
      "layout": {

      },
      "paint": {
        "fill-color": "#E5CCFF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/BVT; Bouvet Island; Bouvet Island; NOR; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        44],
      "layout": {

      },
      "paint": {
        "fill-color": "#E8FDD6",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/BWA; Botswana; Botswana; BWA; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        45],
      "layout": {

      },
      "paint": {
        "fill-color": "#C0DCFE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/CAF; Central African Republic; Central African Republic; CAF; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        46],
      "layout": {

      },
      "paint": {
        "fill-color": "#F5FDBF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/CAN; Canada; Canada; CAN; Member State; North America",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        47],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDB5D6",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/CCK; Cocos (Keeling) Islands; Cocos (Keeling) Is. (Aust.); AUS; Territory; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        48],
      "layout": {

      },
      "paint": {
        "fill-color": "#FFC8C4",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/CHE; Switzerland; Switzerland; CHE; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        49],
      "layout": {

      },
      "paint": {
        "fill-color": "#F4FFC8",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/CHL; Chile; Chile; CHL; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        50],
      "layout": {

      },
      "paint": {
        "fill-color": "#DBCEFC",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/CHN; China; China; CHN; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        51],
      "layout": {

      },
      "paint": {
        "fill-color": "#D8FEFE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/CIV; Côte d'Ivoire; Côte d'Ivoire; CIV; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        52],
      "layout": {

      },
      "paint": {
        "fill-color": "#C6FDD6",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/CMR; Cameroon; Cameroon; CMR; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        53],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEBAE3",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/COD; Democratic Republic of the Congo; Democratic Republic of the Congo; COD; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        54],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEB4DD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/COG; Congo; Congo; COG; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        55],
      "layout": {

      },
      "paint": {
        "fill-color": "#F6D7FF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/COK; Cook Islands; Cook Islands; NZL; Territory; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        56],
      "layout": {

      },
      "paint": {
        "fill-color": "#F1FDD7",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/COL; Colombia; Colombia; COL; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        57],
      "layout": {

      },
      "paint": {
        "fill-color": "#B8D3FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/COM; Comoros; Comoros; COM; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        58],
      "layout": {

      },
      "paint": {
        "fill-color": "#E8CFFE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/CPV; Cabo Verde; Cape Verde; CPV; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        59],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDB7C2",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/CRI; Costa Rica; Costa Rica; CRI; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        60],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDC7F9",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/CUB; Cuba; Cuba; CUB; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        61],
      "layout": {

      },
      "paint": {
        "fill-color": "#B6BDFE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/CUW; Curaçao; Curaçao (Neth.); NLD; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        62],
      "layout": {

      },
      "paint": {
        "fill-color": "#D9BFFF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/CXR; Christmas Island; Christmas Is. (Aust.); AUS; Territory; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        63],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDCABD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/CYM; Cayman Islands; Cayman Islands *; GBR; Non-Self Governing Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        64],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDCAF8",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/CYP; Cyprus; Cyprus; CYP; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        65],
      "layout": {

      },
      "paint": {
        "fill-color": "#E3C6FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/CZE; Czechia; Czechia; CZE; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        66],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEC7C4",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/DEU; Germany; Germany; DEU; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        67],
      "layout": {

      },
      "paint": {
        "fill-color": "#D1FEF5",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/DJI; Djibouti; Djibouti; DJI; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        68],
      "layout": {

      },
      "paint": {
        "fill-color": "#FED0E5",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/DMA; Dominica; Dominica; DMA; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        69],
      "layout": {

      },
      "paint": {
        "fill-color": "#BBD4FF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/DNK; Denmark; Denmark; DNK; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        70],
      "layout": {

      },
      "paint": {
        "fill-color": "#FED8F9",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/DOM; Dominican Republic; Dominican Republic; DOM; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        71],
      "layout": {

      },
      "paint": {
        "fill-color": "#FCD2E1",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/DZA; Algeria; Algeria; DZA; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        72],
      "layout": {

      },
      "paint": {
        "fill-color": "#CADFFF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ECU; Ecuador; Ecuador; ECU; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        73],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDBAC3",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/EGY; Egypt; Egypt; EGY; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        74],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEBBCC",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ERI; Eritrea; Eritrea; ERI; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        75],
      "layout": {

      },
      "paint": {
        "fill-color": "#CAC2FF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ESH; Western Sahara; Western Sahara *; ESH; Non-Self Governing Territory; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        76],
      "layout": {

      },
      "paint": {
        "fill-color": "#FCCCF2",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ESP; Canary Islands; Canary Islands (Sp.); ESP; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        77],
      "layout": {

      },
      "paint": {
        "fill-color": "#DAD2FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ESP; Spain; Spain; ESP; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        78],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDBFCC",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/EST; Estonia; Estonia; EST; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        79],
      "layout": {

      },
      "paint": {
        "fill-color": "#D0FFF2",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ETH; Ethiopia; Ethiopia; ETH; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        80],
      "layout": {

      },
      "paint": {
        "fill-color": "#EAD0FE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/FIN; Finland; Finland; FIN; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        81],
      "layout": {

      },
      "paint": {
        "fill-color": "#C7CAFE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/FJI; Fiji; Fiji; FJI; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        82],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDEFCE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/FLK; Falkland Islands (Malvinas); Falkland Islands (Malvinas) ***; GBR; Non-Self Governing Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        83],
      "layout": {

      },
      "paint": {
        "fill-color": "#B2E9FE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/FRA; France; France; FRA; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        84],
      "layout": {

      },
      "paint": {
        "fill-color": "#D3FBFE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/FRO; Faroe Islands; Faroe Islands (Denmark); DNK; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        85],
      "layout": {

      },
      "paint": {
        "fill-color": "#D7CDFE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/FSM; Micronesia (Federated States of); Micronesia (Federated States of); FSM; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        86],
      "layout": {

      },
      "paint": {
        "fill-color": "#CBC2FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/GAB; Gabon; Gabon; GAB; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        87],
      "layout": {

      },
      "paint": {
        "fill-color": "#C3E5FE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/GBR; United Kingdom of Great Britain & Northern Ireland; United Kingdom of Great Britain & Northern Ireland; GBR; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        88],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDB5FC",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/GEO; Georgia; Georgia; GEO; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        89],
      "layout": {

      },
      "paint": {
        "fill-color": "#E5C8FE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/GGY; Guernsey; Guernsey (UK); GBR; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        90],
      "layout": {

      },
      "paint": {
        "fill-color": "#F5FDD7",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/GHA; Ghana; Ghana; GHA; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        91],
      "layout": {

      },
      "paint": {
        "fill-color": "#C1FFCC",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/GIB; Gibraltar; Gibraltar *; GBR; Non-Self Governing Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        92],
      "layout": {

      },
      "paint": {
        "fill-color": "#D1F1FE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/GIN; Guinea; Guinea; GIN; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        93],
      "layout": {

      },
      "paint": {
        "fill-color": "#D5E2FE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/GLP; Guadeloupe; Guadeloupe (Fr.); FRA; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        94],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDD4FA",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/GMB; Gambia; Gambia; GMB; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        95],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDCBF3",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/GNB; Guinea-Bissau; Guinea-Bissau; GNB; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        96],
      "layout": {

      },
      "paint": {
        "fill-color": "#EDCCFD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/GNQ; Equatorial Guinea; Equatorial Guinea; GNQ; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        97],
      "layout": {

      },
      "paint": {
        "fill-color": "#BCFDD8",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/GRC; Greece; Greece; GRC; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        98],
      "layout": {

      },
      "paint": {
        "fill-color": "#EEFDD6",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/GRD; Grenada; Grenada; GRD; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        99],
      "layout": {

      },
      "paint": {
        "fill-color": "#EFC9FE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/GRL; Greenland; Greenland (Denmark); DNK; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        100],
      "layout": {

      },
      "paint": {
        "fill-color": "#D5FDDB",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/GTM; Guatemala; Guatemala; GTM; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        101],
      "layout": {

      },
      "paint": {
        "fill-color": "#BCFFB8",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/GUF; French Guiana; French Guiana (Fr.); FRA; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        102],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDFDD7",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/GUM; Guam; Guam *; USA; Non-Self Governing Territory; North America",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        103],
      "layout": {

      },
      "paint": {
        "fill-color": "#FFBBDF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/GUY; Guyana; Guyana; GUY; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        104],
      "layout": {

      },
      "paint": {
        "fill-color": "#DFBDFE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/HKG; Hong Kong; Hong Kong, China; CHN; Special Region or Province; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        105],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEE3C2",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/HMD; Heard Island and McDonald Islands; Heard Is. & McDonald Is. (Aust.); AUS; Territory; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        106],
      "layout": {

      },
      "paint": {
        "fill-color": "#C8F9FF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/HND; Honduras; Honduras; HND; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        107],
      "layout": {

      },
      "paint": {
        "fill-color": "#BEFFF1",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/HRV; Croatia; Croatia; HRV; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        108],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDC7ED",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/HTI; Haiti; Haiti; HTI; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        109],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDDCC5",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/HUN; Hungary; Hungary; HUN; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        110],
      "layout": {

      },
      "paint": {
        "fill-color": "#FCBFD8",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/IDN; Indonesia; Indonesia; IDN; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        111],
      "layout": {

      },
      "paint": {
        "fill-color": "#F0C1FE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/IMN; Isle of Man; Isle of Man (UK); GBR; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        112],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEFDCE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/IND; India; India; IND; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        113],
      "layout": {

      },
      "paint": {
        "fill-color": "#F3FFD6",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/IRL; Ireland; Ireland; IRL; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        114],
      "layout": {

      },
      "paint": {
        "fill-color": "#C3E3FC",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/IRN; Iran (Islamic Republic of); Iran (Islamic Republic of); IRN; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        115],
      "layout": {

      },
      "paint": {
        "fill-color": "#FFEFBA",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/IRQ; Iraq; Iraq; IRQ; Member State; West Asia",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        116],
      "layout": {

      },
      "paint": {
        "fill-color": "#FFF7D8",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ISL; Iceland; Iceland; ISL; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        117],
      "layout": {

      },
      "paint": {
        "fill-color": "#C7FEE1",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ISR; Israel; Israel; ISR; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        118],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEFEC1",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ITA; Italy; Italy; ITA; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        119],
      "layout": {

      },
      "paint": {
        "fill-color": "#C3C9FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/JAM; Jamaica; Jamaica; JAM; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        120],
      "layout": {

      },
      "paint": {
        "fill-color": "#B4CCFD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/JEY; Jersey; Jersey (UK); GBR; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        121],
      "layout": {

      },
      "paint": {
        "fill-color": "#DDFEBE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/JOR; Jordan; Jordan; JOR; Member State; West Asia",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        122],
      "layout": {

      },
      "paint": {
        "fill-color": "#C9CFFD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/JPN; Japan; Japan; JPN; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        123],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDD5EC",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/KAZ; Kazakhstan; Kazakhstan; KAZ; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        124],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDE5B2",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/KEN; Kenya; Kenya; KEN; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        125],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEBBBF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/KGZ; Kyrgyzstan; Kyrgyzstan; KGZ; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        126],
      "layout": {

      },
      "paint": {
        "fill-color": "#ECB8FE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/KHM; Cambodia; Cambodia; KHM; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        127],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDD2CC",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/KIR; Kiribati; Kiribati; KIR; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        128],
      "layout": {

      },
      "paint": {
        "fill-color": "#C4DCFD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/KNA; Saint Kitts and Nevis; Saint Kitts and Nevis; KNA; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        129],
      "layout": {

      },
      "paint": {
        "fill-color": "#FED8C4",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/KOR; Republic of Korea; Republic of Korea; KOR; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        130],
      "layout": {

      },
      "paint": {
        "fill-color": "#DFC3FE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/KWT; Kuwait; Kuwait; KWT; Member State; West Asia",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        131],
      "layout": {

      },
      "paint": {
        "fill-color": "#B5C2FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/LAO; Lao People's Democratic Republic; Lao People's Democratic Republic; LAO; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        132],
      "layout": {

      },
      "paint": {
        "fill-color": "#DFC2FF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/LBN; Lebanon; Lebanon; LBN; Member State; West Asia",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        133],
      "layout": {

      },
      "paint": {
        "fill-color": "#F5CFFE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/LBR; Liberia; Liberia; LBR; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        134],
      "layout": {

      },
      "paint": {
        "fill-color": "#D1E8FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/LBY; Libya; Libya; LBY; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        135],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDCBF1",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/LCA; Saint Lucia; Saint Lucia; LCA; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        136],
      "layout": {

      },
      "paint": {
        "fill-color": "#D6FEC7",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/LIE; Liechtenstein; Liechtenstein; LIE; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        137],
      "layout": {

      },
      "paint": {
        "fill-color": "#CDF0FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/LKA; Sri Lanka; Sri Lanka; LKA; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        138],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDDDC9",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/LSO; Lesotho; Lesotho; LSO; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        139],
      "layout": {

      },
      "paint": {
        "fill-color": "#C1DCFE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/LTU; Lithuania; Lithuania; LTU; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        140],
      "layout": {

      },
      "paint": {
        "fill-color": "#E9FDD6",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/LUX; Luxembourg; Luxembourg; LUX; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        141],
      "layout": {

      },
      "paint": {
        "fill-color": "#E1FDC6",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/LVA; Latvia; Latvia; LVA; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        142],
      "layout": {

      },
      "paint": {
        "fill-color": "#F6FECC",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MAC; Macao; Macao, China; CHN; Special Region or Province; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        143],
      "layout": {

      },
      "paint": {
        "fill-color": "#DAC6FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MAF; Saint Martin; Saint Martin (Fr.); FRA; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        144],
      "layout": {

      },
      "paint": {
        "fill-color": "#C7E4FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MAR; Morocco; Morocco; MAR; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        145],
      "layout": {

      },
      "paint": {
        "fill-color": "#C1FDF5",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MCO; Monaco; Monaco; MCO; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        146],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDD4D6",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MDA; Moldova; Moldova; MDA; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        147],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEF6D3",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MDG; Madagascar; Madagascar; MDG; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        148],
      "layout": {

      },
      "paint": {
        "fill-color": "#FFD9C1",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MDV; Maldives; Maldives; MDV; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        149],
      "layout": {

      },
      "paint": {
        "fill-color": "#C7FED0",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MEX; Mexico; Mexico; MEX; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        150],
      "layout": {

      },
      "paint": {
        "fill-color": "#E3C5FE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MHL; Marshall Islands; Marshall Islands; MHL; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        151],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDE0B7",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MKD; North Macedonia; North Macedonia; MKD; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        152],
      "layout": {

      },
      "paint": {
        "fill-color": "#FFB5DA",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MLI; Mali; Mali; MLI; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        153],
      "layout": {

      },
      "paint": {
        "fill-color": "#EAFDBE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MLT; Malta; Malta; MLT; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        154],
      "layout": {

      },
      "paint": {
        "fill-color": "#B2FDD6",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MMR; Myanmar; Myanmar; MMR; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        155],
      "layout": {

      },
      "paint": {
        "fill-color": "#FAC5FE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MNE; Montenegro; Montenegro; MNE; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        156],
      "layout": {

      },
      "paint": {
        "fill-color": "#C1FEE5",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MNG; Mongolia; Mongolia; MNG; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        157],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEBEBE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MNP; Northern Mariana Is. (USA); Northern Mariana Is. (USA); USA; Territory; North America",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        158],
      "layout": {

      },
      "paint": {
        "fill-color": "#D1FDB4",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MOZ; Mozambique; Mozambique; MOZ; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        159],
      "layout": {

      },
      "paint": {
        "fill-color": "#F3C6FE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MRT; Mauritania; Mauritania; MRT; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        160],
      "layout": {

      },
      "paint": {
        "fill-color": "#FCFFD7",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MSR; Montserrat; Montserrat *; GBR; Non-Self Governing Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        161],
      "layout": {

      },
      "paint": {
        "fill-color": "#DDFFC1",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MTQ; Martinique; Martinique (Fr.); FRA; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        162],
      "layout": {

      },
      "paint": {
        "fill-color": "#FFEAC4",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MUS; Chagos Archipelago; Chagos Archipelago (Mauritius); MUS; Territory; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        163],
      "layout": {

      },
      "paint": {
        "fill-color": "#DFBBFD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MUS; Mauritius; Mauritius; MUS; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        164],
      "layout": {

      },
      "paint": {
        "fill-color": "#B7FDDB",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MWI; Malawi; Malawi; MWI; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        165],
      "layout": {

      },
      "paint": {
        "fill-color": "#C8F4FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MYS; Malaysia; Malaysia; MYS; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        166],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDCAF6",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/MYT; Mayotte; Mayotte; FRA; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        167],
      "layout": {

      },
      "paint": {
        "fill-color": "#DAFEB9",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/NAM; Namibia; Namibia; NAM; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        168],
      "layout": {

      },
      "paint": {
        "fill-color": "#C9B3FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/NCL; New Caledonia; New Caledonia *; FRA; Non-Self Governing Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        169],
      "layout": {

      },
      "paint": {
        "fill-color": "#EAC5FE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/NER; Niger; Niger; NER; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        170],
      "layout": {

      },
      "paint": {
        "fill-color": "#C4CBFE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/NFK; Norfolk Island; Norfolk Island (Aust.); AUS; Territory; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        171],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEF6CE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/NGA; Nigeria; Nigeria; NGA; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        172],
      "layout": {

      },
      "paint": {
        "fill-color": "#D1FFC2",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/NIC; Nicaragua; Nicaragua; NIC; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        173],
      "layout": {

      },
      "paint": {
        "fill-color": "#F5CEFD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/NIU; Niue; Niue; NZL; Territory; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        174],
      "layout": {

      },
      "paint": {
        "fill-color": "#B4FDB5",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/NLD; Netherlands; Netherlands; NLD; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        175],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEC6E5",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/NOR; Norway; Norway; NOR; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        176],
      "layout": {

      },
      "paint": {
        "fill-color": "#EEBDFE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/NPL; Nepal; Nepal; NPL; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        177],
      "layout": {

      },
      "paint": {
        "fill-color": "#E4BBFD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/NRU; Nauru; Nauru; NRU; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        178],
      "layout": {

      },
      "paint": {
        "fill-color": "#FFE4C3",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/NZL; New Zealand; New Zealand; NZL; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        179],
      "layout": {

      },
      "paint": {
        "fill-color": "#FED6BA",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/OMN; Oman; Oman; OMN; Member State; West Asia",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        180],
      "layout": {

      },
      "paint": {
        "fill-color": "#B5FBFF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/PAK; Pakistan; Pakistan; PAK; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        181],
      "layout": {

      },
      "paint": {
        "fill-color": "#F1FCD0",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/PAN; Panama; Panama; PAN; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        182],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDC8EE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/PCN; Pitcairn; Pitcairn *; GBR; Non-Self Governing Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        183],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDB3D8",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/PER; Peru; Peru; PER; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        184],
      "layout": {

      },
      "paint": {
        "fill-color": "#D7FFDA",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/PHL; Philippines; Philippines; PHL; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        185],
      "layout": {

      },
      "paint": {
        "fill-color": "#BBFEC5",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/PLW; Palau; Palau; PLW; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        186],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDD2B5",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/PNG; Papua New Guinea; Papua New Guinea; PNG; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        187],
      "layout": {

      },
      "paint": {
        "fill-color": "#B5FDF9",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/POL; Poland; Poland; POL; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        188],
      "layout": {

      },
      "paint": {
        "fill-color": "#FFB3C5",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/PRI; Puerto Rico (USA); Puerto Rico (USA); USA; Territory; North America",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        189],
      "layout": {

      },
      "paint": {
        "fill-color": "#BEB3FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/PRK; Democratic People's Republic of Korea; Democratic People's Republic of Korea; PRK; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        190],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDE4B8",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/PRT; Azores Islands; Azores Islands (Port.); PRT; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        191],
      "layout": {

      },
      "paint": {
        "fill-color": "#E5FEB8",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/PRT; Madeira Island; Madeira Islands (Port.); PRT; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        192],
      "layout": {

      },
      "paint": {
        "fill-color": "#D9FFCD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/PRT; Portugal; Portugal; PRT; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        193],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDFBC1",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/PRY; Paraguay; Paraguay; PRY; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        194],
      "layout": {

      },
      "paint": {
        "fill-color": "#C7FFF9",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/PSE; Gaza; Gaza; PSE; Occupied Palestinian Territory; West Asia",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        195],
      "layout": {

      },
      "paint": {
        "fill-color": "#BBECFE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/PSE; West Bank; West Bank; PSE; Occupied Palestinian Territory; West Asia",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        196],
      "layout": {

      },
      "paint": {
        "fill-color": "#F8FDBF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/PYF; Clipperton Island; Clipperton Island; FRA; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        197],
      "layout": {

      },
      "paint": {
        "fill-color": "#B8FCFD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/PYF; French Polynesia; French Polynesia *; FRA; Non-Self Governing Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        198],
      "layout": {

      },
      "paint": {
        "fill-color": "#CCDBFF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/QAT; Qatar; Qatar; QAT; Member State; West Asia",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        199],
      "layout": {

      },
      "paint": {
        "fill-color": "#F1FECD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/REU; Réunion; Réunion (Fr.); FRA; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        200],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDC3C6",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ROU; Romania; Romania; ROU; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        201],
      "layout": {

      },
      "paint": {
        "fill-color": "#DBFEB4",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/RUS; Russian Federation; Russian Federation; RUS; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        202],
      "layout": {

      },
      "paint": {
        "fill-color": "#BABFFE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/RWA; Rwanda; Rwanda; RWA; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        203],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDC4C0",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SAU; Saudi Arabia; Saudi Arabia; SAU; Member State; West Asia",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        204],
      "layout": {

      },
      "paint": {
        "fill-color": "#B5FFCC",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SDN; Sudan; Sudan; SDN; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        205],
      "layout": {

      },
      "paint": {
        "fill-color": "#B5E1FF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SEN; Senegal; Senegal; SEN; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        206],
      "layout": {

      },
      "paint": {
        "fill-color": "#FFC1D4",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SGP; Singapore; Singapore; SGP; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        207],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDC4E3",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SGS; South Georgia and the South Sandwich Islands; South Georgia and the South Sandwich Is.; GBR; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        208],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDB7CA",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SHN; Saint Helena; Ascencion *; GBR; Non-Self Governing Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        209],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDE7B3",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SHN; Saint Helena; Gough *; GBR; Non-Self Governing Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        210],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDCABB",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SHN; Saint Helena; Saint Helena *; GBR; Non-Self Governing Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        211],
      "layout": {

      },
      "paint": {
        "fill-color": "#BDFEBF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SHN; Saint Helena; Tristan da Cunha *; GBR; Non-Self Governing Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        212],
      "layout": {

      },
      "paint": {
        "fill-color": "#B8E3FE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SJM; Svalbard and Jan Mayen Islands; Svalbard & Jan Mayen Is. (Norw.); NOR; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        213],
      "layout": {

      },
      "paint": {
        "fill-color": "#D4BBFD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SLB; Solomon Islands; Solomon Islands; SLB; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        214],
      "layout": {

      },
      "paint": {
        "fill-color": "#FFEED5",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SLE; Sierra Leone; Sierra Leone; SLE; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        215],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEF0D1",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SLV; El Salvador; El Salvador; SLV; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        216],
      "layout": {

      },
      "paint": {
        "fill-color": "#C5FDCC",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SMR; San Marino; San Marino; SMR; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        217],
      "layout": {

      },
      "paint": {
        "fill-color": "#FFF5C5",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SOM; Somalia; Somalia; SOM; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        218],
      "layout": {

      },
      "paint": {
        "fill-color": "#BFFDE5",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SPM; Saint Pierre et Miquelon; Saint Pierre et Miquelon (Fr.); FRA; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        219],
      "layout": {

      },
      "paint": {
        "fill-color": "#D3FFDC",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SRB; Serbia; Serbia; SRB; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        220],
      "layout": {

      },
      "paint": {
        "fill-color": "#C6F2FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SSD; South Sudan; South Sudan; SSD; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        221],
      "layout": {

      },
      "paint": {
        "fill-color": "#C3FEC9",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/STP; Sao Tome and Principe; Sao Tome and Principe; STP; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        222],
      "layout": {

      },
      "paint": {
        "fill-color": "#C1D9FC",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SUR; Suriname; Suriname; SUR; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        223],
      "layout": {

      },
      "paint": {
        "fill-color": "#DBFFBC",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SVK; Slovakia; Slovakia; SVK; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        224],
      "layout": {

      },
      "paint": {
        "fill-color": "#CCE9FF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SVN; Slovenia; Slovenia; SVN; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        225],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEC5D7",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SWE; Sweden; Sweden; SWE; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        226],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEF5C1",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SWZ; Eswatini; Eswatini; SWZ; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        227],
      "layout": {

      },
      "paint": {
        "fill-color": "#C2C7FF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SXM; Sint Maarten; Sint Maarten (Neth.); NLD; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        228],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEC7BF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SYC; Seychelles; Seychelles; SYC; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        229],
      "layout": {

      },
      "paint": {
        "fill-color": "#C4CEFE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/SYR; Syrian Arab Republic; Syrian Arab Republic; SYR; Member State; West Asia",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        230],
      "layout": {

      },
      "paint": {
        "fill-color": "#E0FED0",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/TCA; Turks and Caicos Islands; Turks and Caicos Islands *; GBR; Non-Self Governing Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        231],
      "layout": {

      },
      "paint": {
        "fill-color": "#DDFDD1",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/TCD; Chad; Chad; TCD; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        232],
      "layout": {

      },
      "paint": {
        "fill-color": "#BBFCFE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/TGO; Togo; Togo; TGO; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        233],
      "layout": {

      },
      "paint": {
        "fill-color": "#E1FECF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/THA; Thailand; Thailand; THA; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        234],
      "layout": {

      },
      "paint": {
        "fill-color": "#CFFFCC",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/TJK; Tajikistan; Tajikistan; TJK; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        235],
      "layout": {

      },
      "paint": {
        "fill-color": "#F0FCBC",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/TKL; Tokelau; Tokelau *; NZL; Non-Self Governing Territory; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        236],
      "layout": {

      },
      "paint": {
        "fill-color": "#F6C1FE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/TKM; Turkmenistan; Turkmenistan; TKM; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        237],
      "layout": {

      },
      "paint": {
        "fill-color": "#B6DBFF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/TLS; Timor-Leste; Timor-Leste; TLS; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        238],
      "layout": {

      },
      "paint": {
        "fill-color": "#F5FDB8",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/TON; Tonga; Tonga; TON; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        239],
      "layout": {

      },
      "paint": {
        "fill-color": "#CACAFF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/TTO; Trinidad and Tobago; Trinidad and Tobago; TTO; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        240],
      "layout": {

      },
      "paint": {
        "fill-color": "#B3FDEF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/TUN; Tunisia; Tunisia; TUN; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        241],
      "layout": {

      },
      "paint": {
        "fill-color": "#C0C4FF",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/TUR; Türkiye; Türkiye; TUR; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        242],
      "layout": {

      },
      "paint": {
        "fill-color": "#D4F8FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/TUV; Tuvalu; Tuvalu; TUV; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        243],
      "layout": {

      },
      "paint": {
        "fill-color": "#D6FEDB",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/TWN; Taiwan; Taiwan, Province of China; CHN; Special Region or Province; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        244],
      "layout": {

      },
      "paint": {
        "fill-color": "#FED6F7",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/TZA; United Republic of Tanzania; United Republic of Tanzania; TZA; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        245],
      "layout": {

      },
      "paint": {
        "fill-color": "#F5FDB9",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/UGA; Uganda; Uganda; UGA; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        246],
      "layout": {

      },
      "paint": {
        "fill-color": "#D3FEF1",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/UKR; Ukraine; Ukraine; UKR; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        247],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEDCD5",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/UMI; Baker Island; Baker Island (USA); USA; Territory; North America",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        248],
      "layout": {

      },
      "paint": {
        "fill-color": "#D1FEBD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/UMI; Howland Island; Howland Island (USA); USA; Territory; North America",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        249],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEC7F5",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/UMI; Jarvis Island; Jarvis Island (USA); USA; Territory; North America",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        250],
      "layout": {

      },
      "paint": {
        "fill-color": "#F9CBFD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/UMI; Johnston Atoll; Johnston Atoll (USA); USA; Territory; North America",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        251],
      "layout": {

      },
      "paint": {
        "fill-color": "#E3B3FE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/UMI; Kingman Reef; Kingman Reef (USA); USA; Territory; North America",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        252],
      "layout": {

      },
      "paint": {
        "fill-color": "#E6D0FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/UMI; Midway Islands; Midway Islands (USA); USA; Territory; North America",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        253],
      "layout": {

      },
      "paint": {
        "fill-color": "#BBFDD4",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/UMI; Navassa Island; Navassa Island (USA); USA; Territory; North America",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        254],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEE0CD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/UMI; Palmyra Atoll; Palmyra Atoll (USA); USA; Territory; North America",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        255],
      "layout": {

      },
      "paint": {
        "fill-color": "#FCFDC5",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/UMI; Wake Island; Wake Island (USA); USA; Territory; North America",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        256],
      "layout": {

      },
      "paint": {
        "fill-color": "#E3C0FE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/URY; Uruguay; Uruguay; URY; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        257],
      "layout": {

      },
      "paint": {
        "fill-color": "#B6D2FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/USA; United States of America; United States of America; USA; Member State; North America",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        258],
      "layout": {

      },
      "paint": {
        "fill-color": "#C5FFBA",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/UZB; Uzbekistan; Uzbekistan; UZB; Member State; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        259],
      "layout": {

      },
      "paint": {
        "fill-color": "#E9D3FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/VAT; Holy See; Holy See; VAT; The City of Vatican; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        260],
      "layout": {

      },
      "paint": {
        "fill-color": "#E9FDC5",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/VCT; Saint Vincent and the Grenadines; Saint Vincent and the Grenadines; VCT; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        261],
      "layout": {

      },
      "paint": {
        "fill-color": "#F5FFD9",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/VEN; Bird Island;  ; VEN; Territory; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        262],
      "layout": {

      },
      "paint": {
        "fill-color": "#CDFDDE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/VEN; Venezuela; Venezuela; VEN; Member State; Latin America and the Caribbean",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        263],
      "layout": {

      },
      "paint": {
        "fill-color": "#CEFDED",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/VGB; British Virgin Islands; British Virgin Islands *; GBR; Non-Self Governing Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        264],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEBCCD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/VIR; United States Virgin Islands; United States Virgin Islands *; USA; Non-Self Governing Territory; North America",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        265],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEE7C7",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/VNM; Viet Nam; Viet Nam; VNM; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        266],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEBBD0",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/VUT; Vanuatu; Vanuatu; VUT; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        267],
      "layout": {

      },
      "paint": {
        "fill-color": "#C8FED3",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/WLF; Wallis and Futuna;  ; FRA; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        268],
      "layout": {

      },
      "paint": {
        "fill-color": "#B3F1FE",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/WSM; Samoa; Samoa; WSM; Member State; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        269],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDB8F7",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/YEM; Yemen; Yemen; YEM; Member State; West Asia",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        270],
      "layout": {

      },
      "paint": {
        "fill-color": "#CCFEE1",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ZAF; South Africa; South Africa; ZAF; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        271],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDBEF3",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ZMB; Zambia; Zambia; ZMB; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        272],
      "layout": {

      },
      "paint": {
        "fill-color": "#CDEBFD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/ZWE; Zimbabwe; Zimbabwe; ZWE; Member State; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        273],
      "layout": {

      },
      "paint": {
        "fill-color": "#DBFFCB",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/xAB; Abyei; Abyei; xAB; Undetermined; Africa",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        274],
      "layout": {

      },
      "paint": {
        "fill-color": "#FDDAC8",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/xAC; Aksai Chin;  ; xAC; Undetermined; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        275],
      "layout": {

      },
      "paint": {
        "fill-color": "#BFC3FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/xAP; Arunachal Pradesh;  ; IND; Undetermined; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        276],
      "layout": {

      },
      "paint": {
        "fill-color": "#BBFDEC",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/xJK; Jammu and Kashmir; Jammu and Kashmir **; xJK; Undetermined; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        277],
      "layout": {

      },
      "paint": {
        "fill-color": "#EDB9FC",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/xPI; Paracel Islands;  ; xPI; Undetermined; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        278],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEFEC6",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/xRI; Kuril Islands;  ; RUS; Undetermined; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        279],
      "layout": {

      },
      "paint": {
        "fill-color": "#FEDBD3",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/xSI; Spratly Islands;  ; xSI; Undetermined; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        280],
      "layout": {

      },
      "paint": {
        "fill-color": "#FFF2BB",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/xSK; Senkaku Islands;  ; JPN; Undetermined; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        281],
      "layout": {

      },
      "paint": {
        "fill-color": "#F3C4FD",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/xSR; Scarborough Reef;  ; xSR; Undetermined; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        282],
      "layout": {

      },
      "paint": {
        "fill-color": "#BEFED5",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/xUK; Akrotiri; Akrotiri (S.B.A.); GBR; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        283],
      "layout": {

      },
      "paint": {
        "fill-color": "#FFEECB",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/xUK; Dekelia; Dekelia (S.B.A.); GBR; Territory; Europe",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        284],
      "layout": {

      },
      "paint": {
        "fill-color": "#ECFDBA",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/xxx; China/India;  ; xxx; Undetermined; Asia and the Pacific",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        285],
      "layout": {

      },
      "paint": {
        "fill-color": "#FED0DB",
        "fill-outline-color": "#6E6E6E"
      }
    },
    {
      "id": "CountryPolygons/\u003Call other values\u003E",
      "type": "fill",
      "source": "esri",
      "source-layer": "CountryPolygons",
      "filter": [
        "==",
        "_symbol",
        286],
      "layout": {

      },
      "paint": {
        "fill-color": "#828282",
        "fill-outline-color": "#6E6E6E"
      }
    }
  ]
      map.on('load', () => {

        map.addSource('esri', {
          type: 'vector',
          tiles: [
            'https://data-gis.unep-wcmc.org/server/rest/services/Hosted/TargetTrackerCountriesTerritories/VectorTileServer/tile/{z}/{y}/{x}.pbf'
          ],
           "maxzoom": 6
        });
        for (const layer of layers) {
          map.addLayer(layer);
        } 
        // Hover highlight layer
        map.addSource('hovered-feature', {
          type: 'geojson',
          data: { type: 'FeatureCollection', features: [] }
        });

        map.addLayer({
          id: 'hover-fill',
          type: 'fill',
          source: 'hovered-feature',
          paint: {
            'fill-color': '#ff9248',
            'fill-opacity': 0.4
          }
        });

        map.addLayer({
          id: 'hover-outline',
          type: 'line',
          source: 'hovered-feature',
          paint: {
            'line-color': '#ff9248',
            'line-width': 2
          }
        });

        // Selected (clicked) feature highlight
        map.addSource('hovered-pa', {
          type: 'geojson',
          data: { type: 'FeatureCollection', features: [] }
        });

        map.addLayer({
          id: 'click-fill',
          type: 'fill',
          source: 'hovered-pa',
          paint: {
            'fill-color': '#154406',
            'fill-opacity': 0.6
          }
        });

        map.addLayer({
          id: 'click-outline',
          type: 'line',
          source: 'hovered-pa',
          paint: {
            'line-color': '#154406',
            'line-width': 3
          }
        });

        // Hover effect
        map.on('mousemove', 'protected_areas', function (e) {
          map.getCanvas().style.cursor = 'pointer';
          const feature = e.features?.[0];
          if (feature) {
            map.getSource('hovered-feature').setData({
              type: 'FeatureCollection',
              features: [feature]
            });
          }
        });

        map.on('mouseleave', 'protected_areas', function () {
          map.getCanvas().style.cursor = '';
          map.getSource('hovered-feature').setData({
            type: 'FeatureCollection',
            features: []
          });
        });

        // Click to cycle through overlapping features
        map.on('click', 'esri', function (e) {
          const clickPoint = `${e.point.x},${e.point.y}`;
          const features = map.queryRenderedFeatures(e.point, {
            layers: ['esri']
          });

          if (!features.length) return;

          if (clickPoint === lastClickPoint) {
            currentIndex = (currentIndex + 1) % features.length;
          } else {
            lastClickPoint = clickPoint;
            overlappingFeatures = features;
            currentIndex = 0;
          }

          const selected = overlappingFeatures[currentIndex];

          map.getSource('hovered-pa').setData({
            type: 'FeatureCollection',
            features: [selected]
          });

        

          const popup = document.getElementById('popupWorldMap');
          popup.innerHTML = selected.properties;
          popup.style.display = 'block';

          const msg = document.getElementById('message');
          if (features.length > 1) {
            msg.innerHTML = `Click again to cycle through ${features.length} overlapping features. Showing ${currentIndex + 1}.`;
          } else {
            msg.innerHTML = `Showing 1 of 1 feature.`;
          }
        });

        // Global click handler to clear selection when clicking empty space
        map.on('click', function (e) {
          const features = map.queryRenderedFeatures(e.point, {
            layers: ['protected_areas']
          });

          if (!features.length) {
            map.getSource('hovered-pa').setData({
              type: 'FeatureCollection',
              features: []
            });

            lastClickPoint = null;
            overlappingFeatures = [];
            currentIndex = 0;

            const msg = document.getElementById('message');
            msg.innerHTML = `No feature selected. Click a site to begin.`;

            const popup = document.getElementById('popup');
            popup.style.display = 'none';
            popup.innerHTML = '';
          }
        });
      });
    }
  },
  mounted() {

    this.wdpaMap();
    this.worldMap();
  }
}
</script>