// Locks page scroll while a `Ref<boolean>` is true — e.g. an overlay or modal that
// sits above the page content, where the page behind it shouldn't scroll.
import type { Ref } from 'vue'
import { watchEffect } from 'vue'

export function useFreezeBackground(active: Ref<boolean>): void {
  watchEffect((onCleanup) => {
    if (active.value) {
      document.body.style.overflow = 'hidden'
      onCleanup(() => {
        document.body.style.overflow = ''
      })
    }
  })
}

export default useFreezeBackground
