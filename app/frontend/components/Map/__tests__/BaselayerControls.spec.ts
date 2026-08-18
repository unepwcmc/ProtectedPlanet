import { describe, it, expect, beforeEach } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import BaselayerControls from '@/components/Map/BaselayerControls.vue'
import { useMapStore } from '@/stores/useMapStore'

const baselayers = [
  { id: 'terrain', name: 'Terrain', style: 'mapbox://styles/unepwcmc/terrain' },
  { id: 'satellite', name: 'Satellite', style: 'mapbox://styles/unepwcmc/satellite' }
]

beforeEach(() => {
  setActivePinia(createPinia())
})

describe('Map BaselayerControls', () => {
  it('selects the first baselayer by default', async () => {
    const wrapper = mount(BaselayerControls, { props: { baselayers } })
    const store = useMapStore()
    await flushPromises()

    expect(store.selectedBaselayer.id).toBe('terrain')
    expect(wrapper.findAll('button')[0].classes()).toContain('ct-map-baselayer-controls__control--selected')
  })

  it('updates the store when a different baselayer is clicked', async () => {
    const wrapper = mount(BaselayerControls, { props: { baselayers } })
    const store = useMapStore()

    await wrapper.findAll('button')[1].trigger('click')

    expect(store.selectedBaselayer.id).toBe('satellite')
  })
})
