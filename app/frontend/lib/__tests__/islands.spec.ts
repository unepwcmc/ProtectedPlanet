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

let unmountCount = 0
// Same shape as Mini, but counts its own teardown — used to prove a removed
// mount point's app instance actually gets unmounted, not just detached.
const CountsUnmount = defineComponent({
  props: { msg: { type: String, default: '' } },
  unmounted() {
    unmountCount++
  },
  render() {
    return h('span', { class: 'counts-unmount' }, `mini:${this.msg}`)
  }
})

// Register once; the registry is module-global (same as in the real app).
registerIslands({
  'mini': () => Promise.resolve({ default: Mini }),
  'counts-unmount': () => Promise.resolve({ default: CountsUnmount })
})

// MutationObserver callbacks and the mounter's dynamic imports resolve async;
// give both a few ticks to settle.
const flush = async (n = 5) => {
  for (let i = 0; i < n; i++) {
    await Promise.resolve()
    await new Promise(r => setTimeout(r, 0))
  }
}

function mountPoint(id: string, props?: Record<string, unknown>, wrapperClass?: string): HTMLElement {
  const el = document.createElement('div')
  el.dataset.mount = id
  if (wrapperClass) el.className = wrapperClass
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
  unmountCount = 0
})

afterEach(() => {
  stopIslands()
  document.body.innerHTML = ''
})

describe('island mounter', () => {
  it('mounts a registered mount point present at start, passing its JSON props', async () => {
    mountPoint('mini', { msg: 'hello' })

    mountAll(document)
    await flush()

    // Note: mounting replaces the wrapper with the component's own root (see
    // islands.ts), so lookups happen against the live document, not a reference to
    // the original (now-detached) wrapper element.
    expect(document.querySelector('.mini')?.textContent).toBe('mini:hello')
  })

  it('carries a class passed to frontend_mount (e.g. layout positioning) onto the mounted root', async () => {
    mountPoint('mini', { msg: 'hello' }, 'topbar__nav nav--primary')

    mountAll(document)
    await flush()

    const root = document.querySelector('.mini')
    expect(root?.classList.contains('topbar__nav')).toBe(true)
    expect(root?.classList.contains('nav--primary')).toBe(true)
  })

  it('ignores unregistered mount ids', async () => {
    const el = mountPoint('does-not-exist')

    mountAll(document)
    await flush()

    expect(el.querySelector('.mini')).toBeNull()
    expect(el.children.length).toBe(0)
  })

  it('does not double-mount the same element', async () => {
    mountPoint('mini', { msg: 'once' })

    mountAll(document)
    mountAll(document) // second scan (e.g. observer + initial) must be a no-op
    await flush()

    expect(document.querySelectorAll('.mini').length).toBe(1)
  })

  it('mounts a mount point ADDED AFTER start (the v-if / late-reveal trap)', async () => {
    // Nothing to mount yet; start scanning + observing.
    startIslands()
    await flush()

    // Simulate a region being revealed later and bringing a mount point with it.
    mountPoint('mini', { msg: 'late' })
    await flush()

    expect(document.querySelector('.mini')?.textContent).toBe('mini:late')
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
    await wrapper.findAll('.ct-tabs__trigger')[1].trigger('click')
    await flush()

    // The observer picked up the newly-inserted mount point and mounted it.
    expect(document.querySelector('[data-mount="mini"]')).not.toBeNull()
    expect(document.querySelector('.mini')?.textContent).toBe('mini:revealed')

    wrapper.unmount()
  })

  it('unmounts the island app when its root is removed from the document', async () => {
    const el = mountPoint('counts-unmount', { msg: 'gone' })

    startIslands()
    await flush()
    expect(document.querySelector('.counts-unmount')).not.toBeNull()

    // The wrapper is swapped for the component's own root on mount (see
    // islands.ts) — look the live node up rather than reusing `el`.
    document.querySelector('.counts-unmount')?.remove()
    await flush()

    expect(unmountCount).toBe(1)
    expect(el.isConnected).toBe(false)
  })

  it('unmounts a nested island when its Tabs panel is torn down by v-if, and re-mounts fresh on return', async () => {
    const tabs = [
      { id: 1, title: 'One', bodyHtml: '<p>plain</p>' },
      {
        id: 2,
        title: 'Two',
        bodyHtml:
          '<div data-mount="counts-unmount"></div>'
          + '<script type="application/json" id="props-counts-unmount">{"msg":"revealed"}</script>'
      }
    ]

    const wrapper = mount(Tabs, { props: { tabs }, attachTo: document.body })
    startIslands()
    await flush()

    await wrapper.findAll('.ct-tabs__trigger')[1].trigger('click')
    await flush()
    expect(document.querySelector('.counts-unmount')).not.toBeNull()
    expect(unmountCount).toBe(0)

    // Switch back to tab 1 — Tabs' own v-if tears down tab 2's panel, taking
    // the nested island's DOM with it.
    await wrapper.findAll('.ct-tabs__trigger')[0].trigger('click')
    await flush()

    expect(document.querySelector('.counts-unmount')).toBeNull()
    expect(unmountCount).toBe(1)

    // Switching back to tab 2 re-inserts the same bodyHtml — must mount a
    // fresh app rather than silently no-op'ing (which would happen if the old
    // element's mounted-tracking entries weren't cleared on removal).
    await wrapper.findAll('.ct-tabs__trigger')[1].trigger('click')
    await flush()

    expect(document.querySelector('.counts-unmount')?.textContent).toBe('mini:revealed')

    wrapper.unmount()
  })
})
