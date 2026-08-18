import { describe, it, expect, afterEach } from 'vitest'
import { defineComponent } from 'vue'
import { mount } from '@vue/test-utils'
import useParcelSelection from '@/composables/useParcelSelection'

function withHash(fn: () => void) {
  const TestComponent = defineComponent({
    setup() {
      fn()
      return () => null
    }
  })
  return mount(TestComponent)
}

afterEach(() => {
  window.history.replaceState({}, '', '/protected-areas/123')
})

describe('useParcelSelection', () => {
  it('reads the initial selection from the site_pid URL param', () => {
    window.history.replaceState({}, '', '/protected-areas/123?site_pid=1234_2')

    withHash(() => {
      const { selectedParcelId } = useParcelSelection()
      expect(selectedParcelId.value).toBe('1234_2')
    })
  })

  it('is null when no site_pid param is present', () => {
    window.history.replaceState({}, '', '/protected-areas/123')

    withHash(() => {
      const { selectedParcelId } = useParcelSelection()
      expect(selectedParcelId.value).toBeNull()
    })
  })

  it('selectParcel writes site_pid to the URL and updates selectedParcelId', () => {
    window.history.replaceState({}, '', '/protected-areas/123')

    withHash(() => {
      const { selectedParcelId, selectParcel } = useParcelSelection()
      selectParcel('1234_1')

      expect(selectedParcelId.value).toBe('1234_1')
      expect(window.location.search).toBe('?site_pid=1234_1')
    })
  })

  it('re-reads the URL when another island selects a parcel', () => {
    window.history.replaceState({}, '', '/protected-areas/123')

    let reader: ReturnType<typeof useParcelSelection> | undefined
    let writer: ReturnType<typeof useParcelSelection> | undefined

    withHash(() => {
      reader = useParcelSelection()
    })
    withHash(() => {
      writer = useParcelSelection()
    })

    writer!.selectParcel('1234_2')

    expect(reader!.selectedParcelId.value).toBe('1234_2')
  })
})
