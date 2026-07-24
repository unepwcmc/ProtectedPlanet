import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import Panel from '@/components/Map/Panel.vue'

const overlays = [
  {
    title: 'Terrestrial',
    layers: [{ id: 'layer-1', type: 'raster_tile' as const, url: 'https://tiles.example/{z}/{x}/{y}.png' }],
    id: 'terrestrial',
    type: 'raster_tile'
  }
]

beforeEach(() => {
  setActivePinia(createPinia())
})

describe('Map Panel', () => {
  it('renders the title and one MapFilter per overlay, body shown by default', () => {
    const wrapper = mount(Panel, { props: { overlays, title: 'Filters' } })

    expect(wrapper.find('.v-map-header__title').text()).toBe('Filters')
    expect(wrapper.findAll('.v-map-filters__overlay')).toHaveLength(1)
    expect(wrapper.find('.v-map-filters__body').isVisible()).toBe(true)
  })

  it('toggles the body visibility when the header close control is clicked', async () => {
    const wrapper = mount(Panel, { props: { overlays, title: 'Filters' } })

    await wrapper.find('.v-map-header__close').trigger('click')

    expect(wrapper.find('.v-map-filters__body').isVisible()).toBe(false)
  })

  it('pulls focusable descendants out of tab order when isHidden is true', () => {
    const wrapper = mount(Panel, { props: { overlays, title: 'Filters', isHidden: true } })

    const toggler = wrapper.find('.v-map-toggler')
    expect(toggler.attributes('tabindex')).toBe('-5')
  })

  it('renders the disclaimer inside the panel when provided', () => {
    const wrapper = mount(Panel, {
      props: { overlays, title: 'Filters', disclaimer: { heading: 'Map Disclaimer', body: 'Some legal text' } }
    })

    expect(wrapper.find('.v-map-filters .v-map-disclaimer__heading').text()).toBe('Map Disclaimer')
  })

  it('does not render a disclaimer when none is provided', () => {
    const wrapper = mount(Panel, { props: { overlays, title: 'Filters' } })

    expect(wrapper.find('.v-map-disclaimer').exists()).toBe(false)
  })
})
