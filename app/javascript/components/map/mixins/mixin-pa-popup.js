import { PointQuery } from '../helpers/request-helpers'
const MARKER_HEIGHT = 18
const MARKER_HALF_WIDTH = 7

export default {
  props: {
    servicesForPointQuery: {
      type: Array,
      default: () => []
    },
    popupAttributes: {
      type: Object,
      default: () => ({
        name: "Name",
        site_id: "ID",
        site_pid: "SITE_PID (Parcel ID)",
      })
    }
  },

  data() {
    return {
      markers: [],
      popups: [],
      popupOffsets: {
        'top': [0, 1],
        'top-left': [0, 1],
        'top-right': [0, 1],
        'bottom': [0, -MARKER_HEIGHT - 20],
        'bottom-left': [0, -MARKER_HEIGHT - 1],
        'bottom-right': [0, -MARKER_HEIGHT - 1],
        'left': [MARKER_HALF_WIDTH + 1, -MARKER_HEIGHT / 2],
        'right': [-MARKER_HALF_WIDTH - 1, -MARKER_HEIGHT / 2]
      }
    }
  },

  methods: {
    onClick(e) {
      this.removeAllMarkersAndPopups()

      const coords = e.lngLat

      new PointQuery(
        this.servicesForPointQuery,
        coords,
        this.addPopupIfFound(coords)
      ).queryAllServices()
    },

    removeAllMarkersAndPopups() {
      this.markers.forEach(marker => { marker.remove() })
      this.markers = []

      this.popups.forEach(popup => { popup.remove() })
      this.popups = []
    },
    generateAttributeHtmlElement(elementType, element) {
      switch (elementType) {
        case 'span':
          return `<span class="mapboxgl-popup-content__wrapper">
                    <span class="mapboxgl-popup-content__title">${element.title}: </span>
                    <span class="mapboxgl-popup-content__value">${element.value}</span> 
                  </span>`
        case 'a':
          return `<span class="mapboxgl-popup-content__wrapper">
                    <span class="mapboxgl-popup-content__title">${element.title}: </span>
                    <a class="mapboxgl-popup-content__link" href="${element.url}">
                      <span class="mapboxgl-popup-content__value">${element.value}</span>
                    </a>
                  </span>`


        default:
          return ''
      }
    },
    generateHtml(attributes) {
      const generateLi = (elementString) => `<li class="mapboxgl-popup-content__attribute">${elementString}</li>`
      const attributesHtml = []
      for (const attribute of attributes) {
        const attributeHtml = generateLi(this.generateAttributeHtmlElement(attribute.url ? 'a' : 'span', attribute))
        attributesHtml.push(attributeHtml)
      }
      return `<ul class="mapboxgl-popup-content__attributes">
                ${attributesHtml.join('')}
              </ul>`

    },
    addPopupIfFound(coords) {
      return res => {
        const features = res.data.features
        let pa = null

        if (features.length) {
          pa = features[0].attributes
          const html = this.generateHtml([
            { title: this.popupAttributes.name, value: pa.name, url: pa.site_id ? `/${pa.site_id}` : undefined },
            { title: this.popupAttributes.site_id, value: pa.site_id },
            { title: this.popupAttributes.site_pid, value: pa.site_pid }
          ])
          this.addPopup(coords, html)
        }

        return pa !== null
      }
    },
    addPopup(coords, htmlString) {
      this.removeAllMarkersAndPopups()
      const pin = document.createElement('div')

      pin.className = 'v-map-pin'

      // eslint-disable-next-line no-undef
      this.popups.push(new mapboxgl.Popup({
        className: 'v-map-pa-popup',
        closeButton: false,
        offset: this.popupOffsets
      }).setLngLat(coords)
        .setHTML(htmlString)
        .setMaxWidth('300px')
        .addTo(this.map)
      )

      // eslint-disable-next-line no-undef
      this.markers.push(new mapboxgl.Marker({ element: pin, anchor: 'bottom' })
        .setLngLat(coords)
        .addTo(this.map)
      )
    }
  }
}