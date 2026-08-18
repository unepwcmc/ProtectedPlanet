import { describe, it, expect, beforeEach } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import Overlay from '@/components/Map/Overlay.vue'
import { useMapStore } from '@/stores/useMapStore'

const layers = [{ id: 'layer-1', type: 'raster_tile' as const, url: 'https://tiles.example/{z}/{x}/{y}.png' }]

beforeEach(() => {
  setActivePinia(createPinia())
})

describe('Map Overlay', () => {
  it('adds its overlay to the store on mount when shown by default', () => {
    mount(Overlay, { props: { title: 'Terrestrial', layers, id: 'terrestrial', type: 'raster_tile' } })
    const store = useMapStore()

    expect(store.visibleOverlays).toEqual([{ id: 'terrestrial', layers }])
    expect(store.visibleLayers).toEqual(layers)
  })

  it('does not add its overlay when isShownByDefault is false', () => {
    mount(Overlay, {
      props: { title: 'Terrestrial', layers, id: 'terrestrial', type: 'raster_tile', isShownByDefault: false }
    })
    const store = useMapStore()

    expect(store.visibleOverlays).toEqual([])
  })

  it('toggles the overlay off the store when the toggler is switched off', async () => {
    const wrapper = mount(Overlay, { props: { title: 'Terrestrial', layers, id: 'terrestrial', type: 'raster_tile' } })
    const store = useMapStore()
    await flushPromises()

    await wrapper.find('.ct-map-toggler').trigger('click')

    expect(store.visibleOverlays.some(o => o.id === 'terrestrial')).toBe(false)
  })

  it('does not render a toggler when isToggleable is false, and clicking has no effect', async () => {
    const wrapper = mount(Overlay, {
      props: { title: 'Terrestrial', layers, id: 'terrestrial', type: 'raster_tile', isToggleable: false }
    })
    const store = useMapStore()

    expect(wrapper.find('.ct-map-toggler').exists()).toBe(false)

    await wrapper.trigger('click')

    expect(store.visibleOverlays).toEqual([{ id: 'terrestrial', layers }])
  })
})
