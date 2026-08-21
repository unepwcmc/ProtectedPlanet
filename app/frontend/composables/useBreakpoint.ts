// Reactive viewport breakpoint. Each caller gets its own resize listener —
// negligible for the handful of components that need this.
import { computed } from 'vue'
import { useWindowSize } from '@vueuse/core'

// MUST match Tailwind's breakpoints.
const BREAKPOINTS = { small: 767, medium: 1024, large: 1200 }

export default function () {
  const { width: windowWidth } = useWindowSize()

  const isSmall = computed(() => windowWidth.value <= BREAKPOINTS.small)
  const isMedium = computed(() => windowWidth.value > BREAKPOINTS.small && windowWidth.value <= BREAKPOINTS.medium)
  const isLarge = computed(() => windowWidth.value > BREAKPOINTS.medium && windowWidth.value <= BREAKPOINTS.large)
  const isXLarge = computed(() => windowWidth.value > BREAKPOINTS.large)

  return { windowWidth, isSmall, isMedium, isLarge, isXLarge }
}
