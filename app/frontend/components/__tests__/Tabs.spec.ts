import { describe, it, expect } from 'vitest'
import { defineComponent, h } from 'vue'
import { mount } from '@vue/test-utils'
import Tabs from '@/components/Tabs.vue'

// Real tab panels hold components. This one records its own mount/unmount so we can
// prove a hidden tab's components are never created until the tab is shown.
const lifecycle: string[] = []
const PanelWidget = defineComponent({
  props: { label: { type: String, required: true } },
  mounted() {
    lifecycle.push(`mount:${this.label}`)
  },
  unmounted() {
    lifecycle.push(`unmount:${this.label}`)
  },
  render() {
    return h('span', { class: 'widget' }, `widget:${this.label}`)
  }
})

const tabs = [
  { id: 1, title: 'First', bodyHtml: '<p class="c1">one</p>' },
  { id: 2, title: 'Second', bodyHtml: '<p class="c2">two</p>' },
  { id: 3, title: 'Third', bodyHtml: '<p class="c3">three</p>' }
]

describe('Tabs (v-if panels)', () => {
  it('renders ONLY the active panel in the DOM; hidden panels are absent', () => {
    const wrapper = mount(Tabs, { props: { tabs } })

    // Active (tab 1) present…
    expect(wrapper.find('[data-tab-panel="1"]').exists()).toBe(true)
    expect(wrapper.find('.c1').exists()).toBe(true)
    // …the others are NOT in the DOM at all (true v-if, not hidden with v-show).
    expect(wrapper.find('[data-tab-panel="2"]').exists()).toBe(false)
    expect(wrapper.find('[data-tab-panel="3"]').exists()).toBe(false)
    expect(wrapper.find('.c2').exists()).toBe(false)
  })

  it('renders a previously-hidden panel when its trigger is clicked', async () => {
    const wrapper = mount(Tabs, { props: { tabs } })

    const secondTrigger = wrapper.findAll('.tab__trigger')[1]
    await secondTrigger.trigger('click')

    // Panel 2 now exists and its body rendered; panel 1 was torn down.
    expect(wrapper.find('[data-tab-panel="2"]').exists()).toBe(true)
    expect(wrapper.find('.c2').text()).toBe('two')
    expect(wrapper.find('[data-tab-panel="1"]').exists()).toBe(false)
    expect(wrapper.emitted('change')?.[0]).toEqual([2])
  })

  it('honours preselectedTab (by id or title)', () => {
    const byId = mount(Tabs, { props: { tabs, preselectedTab: 3 } })
    expect(byId.find('[data-tab-panel="3"]').exists()).toBe(true)

    const byTitle = mount(Tabs, { props: { tabs, preselectedTab: 'Second' } })
    expect(byTitle.find('[data-tab-panel="2"]').exists()).toBe(true)
  })

  it('only mounts the ACTIVE tab\'s slot components; hidden tabs never create theirs', async () => {
    lifecycle.length = 0
    const wrapper = mount(Tabs, {
      props: { tabs: [{ id: 1, title: 'A' }, { id: 2, title: 'B' }] },
      slots: {
        'tab-1': () => h(PanelWidget, { label: 'A' }),
        'tab-2': () => h(PanelWidget, { label: 'B' })
      }
    })

    // Tab 1 active: only widget A was ever created. Widget B does not exist —
    // its slot outlet is inside the v-if that is false, so it is never invoked.
    expect(lifecycle).toEqual(['mount:A'])
    expect(wrapper.findAll('.widget')).toHaveLength(1)
    expect(wrapper.find('.widget').text()).toBe('widget:A')

    // Reveal tab 2: A unmounts, B mounts for the first time.
    await wrapper.findAll('.tab__trigger')[1].trigger('click')

    expect(lifecycle).toEqual(['mount:A', 'unmount:A', 'mount:B'])
    expect(wrapper.findAll('.widget')).toHaveLength(1)
    expect(wrapper.find('.widget').text()).toBe('widget:B')
  })
})
