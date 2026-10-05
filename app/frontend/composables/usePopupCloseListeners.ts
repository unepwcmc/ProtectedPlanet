// Closes an open popup (tooltip, dropdown, ...) on an outside click or Escape.
import type { Ref } from 'vue'
import { onClickOutside, onKeyStroke } from '@vueuse/core'

interface PopupCloseListenersOptions {
  isActive: Ref<boolean>
  onClose: () => void
  closeOnClickOutside?: boolean
  closeOnEscKeypress?: boolean
}

export default function (
  target: Ref<HTMLElement | null>,
  { isActive, onClose, closeOnClickOutside = true, closeOnEscKeypress = true }: PopupCloseListenersOptions
): void {
  if (closeOnClickOutside) {
    onClickOutside(target, () => {
      if (isActive.value) onClose()
    })
  }

  if (closeOnEscKeypress) {
    onKeyStroke('Escape', (e) => {
      if (isActive.value) {
        onClose()
        e.stopPropagation()
      }
    }, { target })
  }
}
