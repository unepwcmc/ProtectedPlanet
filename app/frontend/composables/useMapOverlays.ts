// Shared overlay/layer state for ONE map composition.
//
// Provide/inject rather than a Pinia store: a store is an app-wide singleton
// outliving the Map island, which caused sites to inherit the previous site's
// geometry (addOverlay is idempotent by id, and every PA page ships the same
// overlay id with a different url). Every reader and writer lives inside the
// `Map/Index.vue` tree, so scoping the state there leaves nothing stale to
// reset and lets two maps coexist on a page.
import { inject, provide, ref, type InjectionKey, type Ref } from 'vue'
import type { MapLayer } from '@/composables/useMapLayers'

export interface MapOverlay {
  id: string
  layers: MapLayer[]
}

export interface MapOverlaysContext {
  visibleOverlays: Ref<MapOverlay[]>
  visibleLayers: Ref<MapLayer[]>
  addOverlay: (overlay: MapOverlay) => void
  removeOverlay: (overlay: MapOverlay) => void
}

export const MAP_OVERLAYS_KEY: InjectionKey<MapOverlaysContext> = Symbol('mapOverlays')

/** Build the state for one map composition. Exported for tests; components use the two below. */
export function createMapOverlays(): MapOverlaysContext {
  const visibleOverlays = ref<MapOverlay[]>([])
  const visibleLayers = ref<MapLayer[]>([])

  function addOverlay(overlay: MapOverlay) {
    if (!visibleOverlays.value.some(o => o.id === overlay.id)) {
      visibleOverlays.value = [...visibleOverlays.value, overlay]
    }
    overlay.layers.forEach((layer) => {
      if (!visibleLayers.value.some(l => l.id === layer.id)) {
        visibleLayers.value = [...visibleLayers.value, layer]
      }
    })
  }

  function removeOverlay(overlay: MapOverlay) {
    visibleOverlays.value = visibleOverlays.value.filter(o => o.id !== overlay.id)
    overlay.layers.forEach((layer) => {
      visibleLayers.value = visibleLayers.value.filter(l => l.id !== layer.id)
    })
  }

  return { visibleOverlays, visibleLayers, addOverlay, removeOverlay }
}

/** Called by `Map/Index.vue` only — the root of every map composition. */
export function provideMapOverlays(): MapOverlaysContext {
  const context = createMapOverlays()
  provide(MAP_OVERLAYS_KEY, context)
  return context
}

/**
 * Read/write the enclosing map's overlay state.
 *
 * Throws rather than falling back to a private instance, which would let a
 * component outside a `Map/Index.vue` tree silently talk to state nothing else
 * can see. Tests mounting standalone should pass the context via
 * `global.provide`.
 */
export function useMapOverlays(): MapOverlaysContext {
  const context = inject(MAP_OVERLAYS_KEY, null)
  if (!context) throw new Error('useMapOverlays() must be called inside a Map (Map/Index.vue) tree')
  return context
}
