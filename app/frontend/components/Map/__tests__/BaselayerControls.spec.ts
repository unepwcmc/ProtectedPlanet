import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import BaselayerControls from '@/components/Map/BaselayerControls.vue'

const baselayers = [
  { id: 'terrain', name: 'Terrain', style: 'mapbox://styles/unepwcmc/terrain' },
  { id: 'satellite', name: 'Satellite', style: 'mapbox://styles/unepwcmc/satellite' }
]

describe('Map BaselayerControls', () => {
  it('marks the currently selected baselayer', () => {
    const wrapper = mount(BaselayerControls, { props: { baselayers, modelValue: baselayers[0] } })

    expect(wrapper.findAll('button')[0].classes()).toContain('ct-map-baselayer-controls__control--selected')
    expect(wrapper.findAll('button')[1].classes()).not.toContain('ct-map-baselayer-controls__control--selected')
  })

  it('emits the new baselayer when a different one is clicked', async () => {
    const wrapper = mount(BaselayerControls, { props: { baselayers, modelValue: baselayers[0] } })

    await wrapper.findAll('button')[1].trigger('click')

    expect(wrapper.emitted('update:modelValue')).toEqual([[baselayers[1]]])
  })
})
