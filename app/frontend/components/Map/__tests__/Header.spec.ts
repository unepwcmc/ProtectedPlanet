import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Header from '@/components/Map/Header.vue'
import IconClose from '@/components/Icon/Close.vue'
import IconMinus from '@/components/Icon/Minus.vue'

describe('Map Header', () => {
  it('renders the title and no close control by default', () => {
    const wrapper = mount(Header, { props: { title: 'Filters' } })

    expect(wrapper.find('.ct-map-header__title').text()).toBe('Filters')
    expect(wrapper.find('.ct-map-header__close').exists()).toBe(false)
  })

  it('shows the closed-state icon (filters collapsed) and emits toggle when clicked', async () => {
    const wrapper = mount(Header, { props: { title: 'Filters', closeable: true, filtersShown: false } })

    expect(wrapper.findComponent(IconMinus).exists()).toBe(true)
    expect(wrapper.findComponent(IconClose).exists()).toBe(false)

    await wrapper.find('.ct-map-header__close').trigger('click')

    expect(wrapper.emitted('toggle')).toHaveLength(1)
  })

  it('shows the open-state icon (filters shown) by default when closeable', () => {
    const wrapper = mount(Header, { props: { title: 'Filters', closeable: true, filtersShown: true } })

    expect(wrapper.findComponent(IconClose).exists()).toBe(true)
    expect(wrapper.findComponent(IconMinus).exists()).toBe(false)
  })
})
