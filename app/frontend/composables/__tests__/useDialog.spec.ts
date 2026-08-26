import { describe, it, expect, vi } from 'vitest'
import { defineComponent, h, ref } from 'vue'
import { mount, flushPromises } from '@vue/test-utils'
import useDialog from '@/composables/useDialog'

const onClose = vi.fn()

// attachTo document.body: focus() is a no-op on a detached element, so a trap
// test that does not attach passes for the wrong reason.
function mountDialog() {
  onClose.mockClear()
  const isOpen = ref(false)

  const wrapper = mount(defineComponent({
    setup() {
      const dialogEl = ref<HTMLElement | null>(null)
      useDialog(dialogEl, { isOpen, onClose })

      return () => h('div', {}, [
        h('button', { class: 'outside' }, 'outside'),
        h('div', { ref: dialogEl, class: 'dialog' }, [
          h('button', { class: 'first' }, 'first'),
          h('button', { class: 'last' }, 'last')
        ])
      ])
    }
  }), { attachTo: document.body })

  return { wrapper, isOpen }
}

const press = (key: string, shiftKey = false) =>
  document.dispatchEvent(new KeyboardEvent('keydown', { key, shiftKey, cancelable: true }))

describe('useDialog', () => {
  it('moves focus to the first focusable element on open and back to the opener on close', async () => {
    const { wrapper, isOpen } = mountDialog()
    const opener = wrapper.find('.outside').element as HTMLElement
    opener.focus()

    isOpen.value = true
    await flushPromises()
    expect(document.activeElement).toBe(wrapper.find('.first').element)

    isOpen.value = false
    await flushPromises()
    expect(document.activeElement).toBe(opener)

    wrapper.unmount()
  })

  it('closes on Escape only while open', async () => {
    const { wrapper, isOpen } = mountDialog()

    press('Escape')
    expect(onClose).not.toHaveBeenCalled()

    isOpen.value = true
    await flushPromises()
    press('Escape')
    expect(onClose).toHaveBeenCalledTimes(1)

    wrapper.unmount()
  })

  it('wraps Tab from the last element to the first, and Shift+Tab the other way', async () => {
    const { wrapper, isOpen } = mountDialog()
    isOpen.value = true
    await flushPromises()

    const first = wrapper.find('.first').element as HTMLElement
    const last = wrapper.find('.last').element as HTMLElement

    last.focus()
    press('Tab')
    expect(document.activeElement).toBe(first)

    press('Tab', true)
    expect(document.activeElement).toBe(last)

    wrapper.unmount()
  })

  it('pulls focus back in when it has escaped the dialog', async () => {
    const { wrapper, isOpen } = mountDialog()
    isOpen.value = true
    await flushPromises()

    ;(wrapper.find('.outside').element as HTMLElement).focus()
    press('Tab')

    expect(document.activeElement).toBe(wrapper.find('.first').element)

    wrapper.unmount()
  })

  it('stops trapping once closed', async () => {
    const { wrapper, isOpen } = mountDialog()
    isOpen.value = true
    await flushPromises()
    isOpen.value = false
    await flushPromises()

    const outside = wrapper.find('.outside').element as HTMLElement
    outside.focus()
    press('Tab')

    expect(document.activeElement).toBe(outside)

    wrapper.unmount()
  })
})
