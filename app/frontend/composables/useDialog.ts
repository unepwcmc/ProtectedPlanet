// The keyboard half of a modal dialog, which markup alone cannot express: focus
// moves into the dialog when it opens, Tab cycles inside it instead of walking
// the page behind, Escape closes it, and focus returns to whatever opened it.
//
// Pair it with role="dialog" + aria-modal="true" on the same element, and with
// useFreezeBackground if the page behind should not scroll.
import { nextTick, watch, type Ref } from 'vue'
import { useEventListener } from '@vueuse/core'

// Deliberately not filtered by visibility: jsdom reports every element as having
// no layout, so an offsetParent/getClientRects filter would empty this list in
// every test. Both callers keep their dialog `display: none` while closed, and
// the trap only runs while it is open, so nothing hidden is reachable anyway.
const FOCUSABLE_SELECTOR = [
  'a[href]',
  'button:not([disabled])',
  'input:not([disabled])',
  'select:not([disabled])',
  'textarea:not([disabled])',
  '[tabindex]:not([tabindex="-1"])'
].join(', ')

interface DialogOptions {
  isOpen: Ref<boolean>
  onClose: () => void
}

export default function useDialog(
  dialogEl: Ref<HTMLElement | null>,
  { isOpen, onClose }: DialogOptions
): void {
  let previouslyFocused: HTMLElement | null = null

  const focusableItems = () =>
    Array.from(dialogEl.value?.querySelectorAll<HTMLElement>(FOCUSABLE_SELECTOR) ?? [])

  watch(isOpen, async (open) => {
    if (open) {
      previouslyFocused = document.activeElement as HTMLElement | null
      await nextTick()
      const [firstFocusable] = focusableItems()
      firstFocusable?.focus()
      return
    }

    // Returning focus to the trigger is what makes a dialog usable twice: without
    // it, closing drops the caret back to the top of the document.
    previouslyFocused?.focus()
    previouslyFocused = null
  })

  useEventListener(document, 'keydown', (event: KeyboardEvent) => {
    if (!isOpen.value) return

    if (event.key === 'Escape') {
      event.preventDefault()
      onClose()
      return
    }

    if (event.key !== 'Tab') return

    const items = focusableItems()
    if (!items.length) return

    const first = items[0]
    const last = items[items.length - 1]
    const active = document.activeElement
    const isInside = !!active && !!dialogEl.value?.contains(active)

    if (event.shiftKey && (active === first || !isInside)) {
      event.preventDefault()
      last.focus()
    }
    else if (!event.shiftKey && (active === last || !isInside)) {
      event.preventDefault()
      first.focus()
    }
  })
}
