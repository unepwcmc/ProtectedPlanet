import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import PaginationInfinityScroll from '@/components/PaginationInfinityScroll.vue'

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
})

afterEach(() => {
  vi.unstubAllGlobals()
})

describe('PaginationInfinityScroll', () => {
  it('emits requestMore with the next page when the trigger intersects', () => {
    const wrapper = mount(PaginationInfinityScroll, { props: { total: 20, totalPages: 3 } })

    FakeIntersectionObserver.instances[0].trigger(true)

    expect(wrapper.emitted('requestMore')?.[0]).toEqual([2])
  })

  it('does not request more once the last page has been reached', () => {
    const wrapper = mount(PaginationInfinityScroll, { props: { total: 2, totalPages: 1 } })

    FakeIntersectionObserver.instances[0].trigger(true)

    expect(wrapper.emitted('requestMore')).toBeUndefined()
    expect(wrapper.attributes('style')).toContain('display: none')
  })

  it('resets to page 1 when resetKey changes', async () => {
    const wrapper = mount(PaginationInfinityScroll, { props: { total: 20, totalPages: 3, resetKey: 0 } })

    FakeIntersectionObserver.instances[0].trigger(true)
    expect(wrapper.emitted('requestMore')?.[0]).toEqual([2])

    await wrapper.setProps({ resetKey: 1 })
    FakeIntersectionObserver.instances[0].trigger(true)

    expect(wrapper.emitted('requestMore')?.[1]).toEqual([2])
  })

  it('disconnects the observer on unmount', () => {
    const wrapper = mount(PaginationInfinityScroll, { props: { total: 20, totalPages: 3 } })
    const observer = FakeIntersectionObserver.instances[0]

    wrapper.unmount()

    expect(observer.disconnect).toHaveBeenCalled()
  })

  it('defaults the trigger class to ct-pagination-infinity-scroll__trigger', () => {
    const wrapper = mount(PaginationInfinityScroll, { props: { total: 20, totalPages: 3 } })

    expect(wrapper.classes()).toContain('ct-pagination-infinity-scroll__trigger')
  })

  it('uses a custom triggerClass when provided', () => {
    const wrapper = mount(PaginationInfinityScroll, {
      props: { triggerClass: 'sm-trigger-infinite-scroll', total: 20, totalPages: 3 }
    })

    expect(wrapper.classes()).toContain('sm-trigger-infinite-scroll')
  })
})
