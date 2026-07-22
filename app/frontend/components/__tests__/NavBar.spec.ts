import { describe, it, expect, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import NavBar from '@/components/NavBar/Index.vue'

const links = [
  { id: 'home', label: 'Home', url: '/en', is_current_page: true },
  {
    id: 'data',
    label: 'Data',
    url: '/en/data',
    is_current_page: false,
    children: [{ id: 'wdpa', label: 'WDPA', url: '/en/data/wdpa', is_current_page: false }]
  }
]

function setWindowWidth(width: number) {
  Object.defineProperty(window, 'innerWidth', { writable: true, configurable: true, value: width })
  window.dispatchEvent(new Event('resize'))
}

// v-show toggles an inline `display` style; jsdom's :hidden-based isVisible()
// heuristic is unreliable for detached/rapidly-toggled trees, so assert on the
// inline style directly instead (see Tooltip.spec.ts for the same fix).
function isShown(wrapper: { attributes: (name: string) => string | undefined }): boolean {
  return !(wrapper.attributes('style') ?? '').includes('display: none')
}

describe('NavBar', () => {
  afterEach(() => setWindowWidth(1024))

  it('renders a link and a dropdown for a link with children', () => {
    const wrapper = mount(NavBar, { props: { links } })

    expect(wrapper.findAll('.nav__li')).toHaveLength(2)
    expect(wrapper.find('.nav__a').exists()).toBe(true)
    expect(wrapper.find('.nav__dropdown').exists()).toBe(true)
  })

  it('shows the burger toggle on a narrow viewport and opens/closes the pane', async () => {
    setWindowWidth(500)
    const wrapper = mount(NavBar, { props: { links }, attachTo: document.body })
    await wrapper.vm.$nextTick()

    expect(isShown(wrapper.find('.nav__burger'))).toBe(true)
    expect(wrapper.find('.nav__pane').classes()).not.toContain('nav-pane--active')

    await wrapper.find('.nav__burger').trigger('click')
    expect(wrapper.find('.nav__pane').classes()).toContain('nav-pane--active')

    await wrapper.find('.nav__close').trigger('click')
    expect(wrapper.find('.nav__pane').classes()).not.toContain('nav-pane--active')

    wrapper.unmount()
  })

  it('hides the burger toggle above the mobile breakpoint (767px), for any wider viewport', async () => {
    // _nav.scss only branches at $small (767px) — there's no separate $medium/$large
    // split in the CSS, so burger mode is "mobile" only. An earlier port used
    // `!isLarge()` (true outside the 1024-1200px bucket only), a legacy bug that
    // made the burger reappear above 1200px; fixed to match the CSS breakpoint.
    for (const width of [1100, 1300]) {
      setWindowWidth(width)
      const wrapper = mount(NavBar, { props: { links } })
      await wrapper.vm.$nextTick()

      expect(isShown(wrapper.find('.nav__burger'))).toBe(false)
      wrapper.unmount()
    }
  })

  it('always shows the burger toggle when isAlwaysBurger is set, regardless of viewport', async () => {
    setWindowWidth(1100)
    const wrapper = mount(NavBar, { props: { links, isAlwaysBurger: true } })
    await wrapper.vm.$nextTick()

    expect(isShown(wrapper.find('.nav__burger'))).toBe(true)
  })

  it('closes the pane when clicking outside', async () => {
    setWindowWidth(500)
    const wrapper = mount(NavBar, { props: { links }, attachTo: document.body })
    await wrapper.vm.$nextTick()

    await wrapper.find('.nav__burger').trigger('click')
    expect(wrapper.find('.nav__pane').classes()).toContain('nav-pane--active')

    // vueuse's onClickOutside briefly guards against double-firing for the same
    // click sequence (touch+click), so a synchronous second click right after the
    // first is ignored — let a macrotask pass first, same as a real user would.
    await new Promise(resolve => setTimeout(resolve, 0))

    document.body.click()
    await wrapper.vm.$nextTick()
    expect(wrapper.find('.nav__pane').classes()).not.toContain('nav-pane--active')

    wrapper.unmount()
  })
})
