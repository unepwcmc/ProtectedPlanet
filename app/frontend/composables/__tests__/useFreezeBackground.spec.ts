import { describe, it, expect } from 'vitest'
import { defineComponent, ref } from 'vue'
import { mount } from '@vue/test-utils'
import { useFreezeBackground } from '@/composables/useFreezeBackground'

describe('useFreezeBackground', () => {
  it('locks and restores body scroll as the ref toggles, and restores on unmount', async () => {
    const active = ref(false)
    const wrapper = mount(defineComponent({
      setup() {
        useFreezeBackground(active)
        return () => null
      }
    }))

    expect(document.body.style.overflow).toBe('')

    active.value = true
    await wrapper.vm.$nextTick()
    expect(document.body.style.overflow).toBe('hidden')

    active.value = false
    await wrapper.vm.$nextTick()
    expect(document.body.style.overflow).toBe('')

    active.value = true
    await wrapper.vm.$nextTick()
    wrapper.unmount()
    expect(document.body.style.overflow).toBe('')
  })
})
