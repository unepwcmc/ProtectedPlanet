import { describe, it, expect, beforeEach } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import Overlay from '@/components/Map/Overlay.vue'
import { createMapOverlays, MAP_OVERLAYS_KEY, type MapOverlaysContext } from '@/composables/useMapOverlays'
import type { MapFilterProps } from '@/types/backend'

const layers = [{ id: 'layer-1', type: 'raster_tile' as const, url: 'https://tiles.example/{z}/{x}/{y}.png' }]

// Overlay.vue is only ever rendered inside a Map/Index.vue tree, which provides this;
// standalone it throws on purpose (see useMapOverlays.ts).
let context: MapOverlaysContext

beforeEach(() => {
  context = createMapOverlays()
})

const mountOverlay = (props: Partial<MapFilterProps> = {}) =>
  mount(Overlay, {
    props: { title: 'Terrestrial', layers, id: 'terrestrial', type: 'raster_tile', ...props },
    global: { provide: { [MAP_OVERLAYS_KEY as symbol]: context } }
  })

describe('Map Overlay', () => {
  it('registers its overlay on mount when shown by default', () => {
    mountOverlay()

    expect(context.visibleOverlays.value).toEqual([{ id: 'terrestrial', layers }])
    expect(context.visibleLayers.value).toEqual(layers)
  })

  it('does not register its overlay when isShownByDefault is false', () => {
    mountOverlay({ isShownByDefault: false })

    expect(context.visibleOverlays.value).toEqual([])
  })

  it('deregisters the overlay when the toggler is switched off', async () => {
    const wrapper = mountOverlay()
    await flushPromises()

    await wrapper.find('.ct-map-toggler').trigger('click')

    expect(context.visibleOverlays.value.some(o => o.id === 'terrestrial')).toBe(false)
    expect(context.visibleLayers.value).toEqual([])
  })

  it('does not render a toggler when isToggleable is false, and clicking has no effect', async () => {
    const wrapper = mountOverlay({ isToggleable: false })

    expect(wrapper.find('.ct-map-toggler').exists()).toBe(false)

    await wrapper.trigger('click')

    expect(context.visibleOverlays.value).toEqual([{ id: 'terrestrial', layers }])
  })
})
