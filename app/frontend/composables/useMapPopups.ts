import { shallowRef, type Ref } from 'vue'
import { Marker, Popup, type Map as MapLibreMap, type MapMouseEvent } from 'maplibre-gl'
import { getJsonExternal } from '@/lib/http'
import type { PointQueryService, PopupAttributeLabels } from '@/types/map'
import { POPUP_OFFSETS } from '@/constants/map'

interface PointFeature {
  attributes: { name?: string, site_id?: string, site_pid?: string }
}

function buildQueryString(coords: { lng: number, lat: number }, isPoint?: boolean, additionalQueryParams = ''): string {
  let queryString = `/query?geometry=${coords.lng}%2C+${coords.lat}&geometryType=esriGeometryPoint&returnGeometry=false&inSR=4326&outFields=site_id,site_pid%2Cname&f=json`

  if (additionalQueryParams) queryString += `&${additionalQueryParams}`
  if (isPoint) queryString += '&distance=5&units=esriSRUnit_StatuteMile'

  return queryString
}

async function queryServicesForPoint(
  services: PointQueryService[],
  coords: { lng: number, lat: number }
): Promise<PointFeature | null> {
  for (const service of services) {
    const queryString = buildQueryString(coords, service.isPoint, service.queryString || '')
    const res = await getJsonExternal<{ features: PointFeature[] }>(service.url + queryString)

    if (res.features.length) return res.features[0]
  }

  return null
}

function attributeHtml(elementType: 'span' | 'a', element: { title: string, value?: string, url?: string }): string {
  if (elementType === 'a') {
    return `<span class="maplibregl-popup-content__wrapper">
              <span class="maplibregl-popup-content__title">${element.title}: </span>
              <a class="maplibregl-popup-content__link" href="${element.url}">
                <span class="maplibregl-popup-content__value">${element.value}</span>
              </a>
            </span>`
  }

  return `<span class="maplibregl-popup-content__wrapper">
            <span class="maplibregl-popup-content__title">${element.title}: </span>
            <span class="maplibregl-popup-content__value">${element.value}</span>
          </span>`
}

export default function (
  map: Ref<MapLibreMap | null>,
  servicesForPointQuery: PointQueryService[],
  popupAttributes: PopupAttributeLabels = { name: 'Name', site_id: 'ID', site_pid: 'SITE_PID (Parcel ID)' }
) {
  // shallowRef: Marker/Popup are GL instances with deep circular internals, and
  // a plain ref()'s UnwrapRef blows past TS's recursion limit on them.
  const markers = shallowRef<Marker[]>([])
  const popups = shallowRef<Popup[]>([])

  function removeAllMarkersAndPopups() {
    markers.value.forEach(marker => marker.remove())
    markers.value = []
    popups.value.forEach(popup => popup.remove())
    popups.value = []
  }

  function addPopup(coords: { lng: number, lat: number }, htmlString: string) {
    const currentMap = map.value
    if (!currentMap) return

    removeAllMarkersAndPopups()

    const pin = document.createElement('div')
    pin.className = 'tw-shared-icon-pin-map'

    const popup = new Popup({ closeButton: false, offset: POPUP_OFFSETS })
    popup.setLngLat(coords)
    popup.setHTML(htmlString)
    popup.setMaxWidth('300px')
    popup.addTo(currentMap)
    popups.value.push(popup)

    const marker = new Marker({ element: pin, anchor: 'bottom' })
    marker.setLngLat(coords)
    marker.addTo(currentMap)
    markers.value.push(marker)
  }

  function generateAttributesHtml(attributes: Array<{ title: string, value?: string, url?: string }>): string {
    const items = attributes
      .map(a => `<li class="maplibregl-popup-content__attribute">${attributeHtml(a.url ? 'a' : 'span', a)}</li>`)
      .join('')

    return `<ul class="maplibregl-popup-content__attributes">${items}</ul>`
  }

  async function onClick(e: MapMouseEvent) {
    removeAllMarkersAndPopups()

    const coords = e.lngLat
    const feature = await queryServicesForPoint(servicesForPointQuery, coords)

    if (!feature) return

    const pa = feature.attributes
    const html = generateAttributesHtml([
      { title: popupAttributes.name, value: pa.name, url: pa.site_id ? `/${pa.site_id}` : undefined },
      { title: popupAttributes.site_id, value: pa.site_id },
      { title: popupAttributes.site_pid, value: pa.site_pid }
    ])

    addPopup(coords, html)
  }

  return {
    onClick,
    addPopup,
    removeAllMarkersAndPopups,
    generateAttributesHtml,
    popupAttributes
  }
}
