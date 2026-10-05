import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { nextTick } from 'vue'
import { mount } from '@vue/test-utils'
import Counter from '@/components/Counter.vue'

// Stand-in for IntersectionObserver, absent from jsdom, so a test can trigger
// the "trigger became visible" path itself.
class FakeIntersectionObserver {
  static instances: FakeIntersectionObserver[] = []
  callback: IntersectionObserverCallback

  constructor(callback: IntersectionObserverCallback) {
    this.callback = callback
    FakeIntersectionObserver.instances.push(this)
  }

  observe = vi.fn()
  disconnect = vi.fn()
  unobserve = vi.fn()

  trigger(isIntersecting: boolean) {
    this.callback(
      [{ isIntersecting } as IntersectionObserverEntry],
      this as unknown as IntersectionObserver
    )
  }
}

beforeEach(() => {
  FakeIntersectionObserver.instances = []
  vi.stubGlobal('IntersectionObserver', FakeIntersectionObserver)
  document.body.innerHTML = '<div class="stats-trigger"></div>'
  vi.useFakeTimers()
})

afterEach(() => {
  vi.useRealTimers()
  vi.unstubAllGlobals()
})

describe('Counter', () => {
  it('counts up immediately when animate is true', async () => {
    const wrapper = mount(Counter, {
      props: { total: 100, trigger: 'stats-trigger', animate: true, decimal: 0 }
    })

    vi.runAllTimers()
    // The interval's ref updates batch into a microtask flush fake timers do
    // not drive — let it run before reading the text.
    await nextTick()

    expect(wrapper.text()).toBe('100')
  })

  it('counts up once the trigger element intersects the viewport', async () => {
    const wrapper = mount(Counter, {
      props: { total: 50, trigger: 'stats-trigger', decimal: 0 }
    })

    expect(wrapper.text()).toBe('0')

    FakeIntersectionObserver.instances[0].trigger(true)
    vi.runAllTimers()
    await nextTick()

    expect(wrapper.text()).toBe('50')
  })

  it('does not count before the trigger intersects', () => {
    const wrapper = mount(Counter, {
      props: { total: 50, trigger: 'stats-trigger', decimal: 0 }
    })

    vi.advanceTimersByTime(1000)

    expect(wrapper.text()).toBe('0')
  })
})
