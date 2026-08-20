import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Panel from '@/components/Map/Panel.vue'
import { createMapOverlays, MAP_OVERLAYS_KEY } from '@/composables/useMapOverlays'
import type { MapPanelProps } from '@/types/backend'

const overlays = [
  {
    title: 'Terrestrial',
    layers: [{ id: 'layer-1', type: 'raster_tile' as const, url: 'https://tiles.example/{z}/{x}/{y}.png' }],
    id: 'terrestrial',
    type: 'raster_tile'
  }
]

// Panel's MapOverlay children read the state Map/Index.vue provides; standalone they
// throw on purpose (see useMapOverlays.ts).
const mountPanel = (props: MapPanelProps) =>
  mount(Panel, { props, global: { provide: { [MAP_OVERLAYS_KEY as symbol]: createMapOverlays() } } })

describe('Map Panel', () => {
  it('renders the title and one MapFilter per overlay, body shown by default', () => {
    const wrapper = mountPanel({ overlays, title: 'Filters' })

    expect(wrapper.find('.ct-map-header__title').text()).toBe('Filters')
    expect(wrapper.findAll('.ct-map-overlay')).toHaveLength(1)
    expect(wrapper.find('.ct-map-panel__body').isVisible()).toBe(true)
  })

  it('toggles the body visibility when the header close control is clicked', async () => {
    const wrapper = mountPanel({ overlays, title: 'Filters' })

    await wrapper.find('.ct-map-header__close').trigger('click')

    expect(wrapper.find('.ct-map-panel__body').isVisible()).toBe(false)
  })

  it('pulls focusable descendants out of tab order when isHidden is true', () => {
    const wrapper = mountPanel({ overlays, title: 'Filters', isHidden: true })

    const toggler = wrapper.find('.ct-map-toggler')
    expect(toggler.attributes('tabindex')).toBe('-5')
  })

  it('renders the disclaimer inside the panel when provided', () => {
    const wrapper = mountPanel({
      overlays,
      title: 'Filters',
      disclaimer: { heading: 'Map Disclaimer', body: 'Some legal text' }
    })

    expect(wrapper.find('.ct-map-panel .ct-map-disclaimer__heading').text()).toBe('Map Disclaimer')
  })

  it('does not render a disclaimer when none is provided', () => {
    const wrapper = mountPanel({ overlays, title: 'Filters' })

    expect(wrapper.find('.ct-map-disclaimer').exists()).toBe(false)
  })
})
