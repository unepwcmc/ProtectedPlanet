import { describe, it, expect, afterEach, beforeEach } from 'vitest'
import { defineComponent, h } from 'vue'
import { mount } from '@vue/test-utils'
import { registerIslands, mountAll, startIslands, stopIslands } from '@/lib/islands'
import Tabs from '@/components/Tabs.vue'

// A trivial Vue 3 island (render fn so no runtime template compiler is needed).
const Mini = defineComponent({
  props: { msg: { type: String, default: '' } },
  render() {
    return h('span', { class: 'mini' }, `mini:${this.msg}`)
  }
})

// Register once; the registry is module-global (same as in the real app).
registerIslands({ mini: () => Promise.resolve({ default: Mini }) })

// MutationObserver callbacks and the mounter's dynamic imports resolve async;
// give both a few ticks to settle.
const flush = async (n = 5) => {
  for (let i = 0; i < n; i++) {
    await Promise.resolve()
    await new Promise(r => setTimeout(r, 0))
  }
}

function mountPoint(id: string, props?: Record<string, unknown>): HTMLElement {
  const el = document.createElement('div')
  el.dataset.mount = id
  document.body.appendChild(el)
  if (props) {
    const script = document.createElement('script')
    script.type = 'application/json'
    script.id = `props-${id}`
    script.textContent = JSON.stringify(props)
    document.body.appendChild(script)
  }
  return el
}

beforeEach(() => {
  document.body.innerHTML = ''
})

afterEach(() => {
  stopIslands()
  document.body.innerHTML = ''
})

describe('island mounter', () => {
  it('mounts a registered mount point present at start, passing its JSON props', async () => {
    const el = mountPoint('mini', { msg: 'hello' })

    mountAll(document)
    await flush()

    expect(el.querySelector('.mini')?.textContent).toBe('mini:hello')
  })

  it('ignores unregistered mount ids', async () => {
    const el = mountPoint('does-not-exist')

    mountAll(document)
    await flush()

    expect(el.querySelector('.mini')).toBeNull()
    expect(el.children.length).toBe(0)
  })

  it('does not double-mount the same element', async () => {
    const el = mountPoint('mini', { msg: 'once' })

    mountAll(document)
    mountAll(document) // second scan (e.g. observer + initial) must be a no-op
    await flush()

    expect(el.querySelectorAll('.mini').length).toBe(1)
  })

  it('mounts a mount point ADDED AFTER start (the v-if / late-reveal trap)', async () => {
    // Nothing to mount yet; start scanning + observing.
    startIslands()
    await flush()

    // Simulate a region being revealed later and bringing a mount point with it.
    const el = mountPoint('mini', { msg: 'late' })
    await flush()

    expect(el.querySelector('.mini')?.textContent).toBe('mini:late')
  })

  it('mounts a nested island inside a Tabs panel that is v-if-hidden by default', async () => {
    // Tab 2 carries a nested island in its CMS bodyHtml. Tab 1 is active, so the
    // nested mount point is NOT in the DOM initially.
    const tabs = [
      { id: 1, title: 'One', bodyHtml: '<p>plain</p>' },
      {
        id: 2,
        title: 'Two',
        bodyHtml:
          '<div data-mount="mini"></div>'
          + '<script type="application/json" id="props-mini">{"msg":"revealed"}</script>'
      }
    ]

    const wrapper = mount(Tabs, { props: { tabs }, attachTo: document.body })
    startIslands()
    await flush()

    // Hidden by default: no nested mount point, nothing mounted.
    expect(document.querySelector('[data-mount="mini"]')).toBeNull()
    expect(document.querySelector('.mini')).toBeNull()

    // Reveal tab 2 -> its bodyHtml (incl. the nested mount point) enters the DOM.
    await wrapper.findAll('.tab__trigger')[1].trigger('click')
    await flush()

    // The observer picked up the newly-inserted mount point and mounted it.
    expect(document.querySelector('[data-mount="mini"]')).not.toBeNull()
    expect(document.querySelector('.mini')?.textContent).toBe('mini:revealed')

    wrapper.unmount()
  })
})
