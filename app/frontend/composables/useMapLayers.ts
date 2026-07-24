// Vue3 port of app/javascript/components/map/mixins/{mixin-layers,mixin-add-layers}.js
import { ref, type Ref } from 'vue'
import type { Map as MapLibreMap } from 'maplibre-gl'
import { executeAfterCondition } from '@/lib/timing'

export interface MapLayer {
  id: string
  type: 'raster_tile' | 'raster_data'
  url: string
  isPoint?: boolean
  color?: string
}

export function useMapLayers(map: Ref<MapLibreMap | null>) {
  const firstForegroundLayerId = ref('')

  function executeAfterStyleLoad(callback: () => void) {
    executeAfterCondition(() => Boolean(map.value?.isStyleLoaded?.()), callback)
  }

  function getFirstForegroundLayerId(): string {
    const layers = map.value?.getStyle()?.layers ?? []
    let firstBoundaryId = ''
    let firstSymbolId = ''

    for (const layer of layers) {
      if (layer.id.match('admin') && layer.id.match('boundary')) {
        firstBoundaryId = layer.id
        break
      }
      else if (layer.type === 'symbol') {
        firstSymbolId = layer.id
      }
    }

    return firstBoundaryId || firstSymbolId
  }

  function setFirstForegroundLayerId() {
    firstForegroundLayerId.value = getFirstForegroundLayerId()
  }

  function hasExistingMapLayer(id: string): boolean {
    return Boolean(map.value?.getLayer(id))
  }

  function addRasterTileLayer(layer: MapLayer) {
    if (!map.value || hasExistingMapLayer(layer.id)) return

    map.value.addLayer(
      {
        id: layer.id,
        type: 'raster',
        minzoom: 0,
        maxzoom: 22,
        source: {
          type: 'raster',
          tiles: [layer.url],
          tileSize: 128
        },
        layout: { visibility: 'visible' }
      },
      firstForegroundLayerId.value || undefined
    )
  }

  function addRasterDataLayer(layer: MapLayer) {
    if (!map.value || hasExistingMapLayer(layer.id)) return

    const paint = layer.isPoint
      ? {
          type: 'circle' as const,
          paint: {
            'circle-radius': ['interpolate', ['exponential', 1], ['zoom'], 0, 1.5, 6, 4] as unknown as number,
            'circle-color': layer.color,
            'circle-opacity': 0.7
          }
        }
      : {
          type: 'fill' as const,
          paint: {
            'fill-color': layer.color,
            'fill-opacity': 0.8
          }
        }

    map.value.addLayer(
      {
        id: layer.id,
        source: { type: 'geojson', data: layer.url },
        layout: { visibility: 'visible' },
        ...paint
      },
      firstForegroundLayerId.value || undefined
    )
  }

  function addLayer(layer: MapLayer) {
    if (layer.type === 'raster_tile') {
      addRasterTileLayer(layer)
    }
    else if (layer.type === 'raster_data') {
      addRasterDataLayer(layer)
    }
  }

  function addLayerBeneathBoundariesAndLabels(layer: MapLayer) {
    executeAfterCondition(() => Boolean(firstForegroundLayerId.value), () => addLayer(layer), 10)
  }

  function setLayerVisibility(layer: { id: string }, isVisible: boolean) {
    if (!map.value?.getLayer(layer.id)) return
    map.value.setLayoutProperty(layer.id, 'visibility', isVisible ? 'visible' : 'none')
  }

  function showLayer(layer: MapLayer) {
    const existing = map.value?.getLayer(layer.id)
    const isVisible = existing && existing.visibility === 'visible'

    if (!existing) {
      addLayerBeneathBoundariesAndLabels(layer)
    }
    else if (!isVisible) {
      setLayerVisibility(layer, true)
    }
  }

  function showLayers(layers: MapLayer[]) {
    executeAfterStyleLoad(() => layers.forEach(showLayer))
  }

  function hideLayers(layers: Array<{ id: string }>) {
    layers.forEach(l => setLayerVisibility(l, false))
  }

  return {
    firstForegroundLayerId,
    executeAfterStyleLoad,
    setFirstForegroundLayerId,
    showLayers,
    hideLayers,
    addLayer,
    hasExistingMapLayer
  }
}
