import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Header from '@/components/Map/Header.vue'

describe('Map Header', () => {
  it('renders the title and no close control by default', () => {
    const wrapper = mount(Header, { props: { title: 'Filters' } })

    expect(wrapper.find('.v-map-header__title').text()).toBe('Filters')
    expect(wrapper.find('.v-map-header__close').exists()).toBe(false)
  })

  it('shows a closed-state close control and emits toggle when clicked', async () => {
    const wrapper = mount(Header, { props: { title: 'Filters', closeable: true, filtersShown: false } })

    const close = wrapper.find('.v-map-header__close')
    expect(close.classes()).toContain('closed')

    await close.trigger('click')

    expect(wrapper.emitted('toggle')).toHaveLength(1)
  })
})
