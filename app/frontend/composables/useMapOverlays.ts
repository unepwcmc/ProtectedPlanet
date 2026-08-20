// Shared overlay/layer state for ONE map composition.
//
// This was previously a Pinia store (`stores/useMapStore.ts`, itself a port of the
// legacy Vuex `map` module). Pinia stores are app-wide singletons that survive Turbo
// Drive navigation, while the Map island is torn down and rebuilt on every page --
// a mismatch that caused two separate "the highlighted area disappeared" bugs
// (the second site inheriting the first site's geometry, because `addOverlay` is
// idempotent by id and every PA page ships the same overlay id with a different
// site-specific url). Both were patched with a manual reset + a resync-on-init.
//
// The state was never actually app-wide: every reader and writer lives inside the
// `Map/Index.vue` tree, which is always mounted whole (`turbo_mount "Map"`).
// Scoping it to that tree via provide/inject removes the mismatch at the root --
// each mount gets its own state, so there is nothing stale to reset -- and lets two
// maps coexist on one page without fighting over a single global.
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
 * Throws rather than falling back to a private instance: a `MapOverlay` or `MapBase`
 * outside a `Map/Index.vue` tree would otherwise silently talk to state nothing else
 * can see -- exactly the class of "the layer never showed up" bug this replaced.
 * Tests mounting these components standalone should pass the context via
 * `global.provide`.
 */
export function useMapOverlays(): MapOverlaysContext {
  const context = inject(MAP_OVERLAYS_KEY, null)
  if (!context) throw new Error('useMapOverlays() must be called inside a Map (Map/Index.vue) tree')
  return context
}
