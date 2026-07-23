// Vue 3 replacement for the legacy Vue 2 `mixin-responsive` mixin
// (app/javascript/mixins/mixin-responsive.js). That mixin broadcast resize via
// a global `$eventHub` so several component instances could share one resize
// listener; Vue 3 has no such global bus here, so each caller gets its own
// listener — negligible cost for the handful of components that need this.
import { computed } from 'vue'
import { useWindowSize } from '@vueuse/core'

// MUST match the breakpoints in app/assets/stylesheets/_settings.
const BREAKPOINTS = { small: 767, medium: 1024, large: 1200 }

export function useBreakpoint() {
  const { width: windowWidth } = useWindowSize()

  const isSmall = computed(() => windowWidth.value <= BREAKPOINTS.small)
  const isMedium = computed(() => windowWidth.value > BREAKPOINTS.small && windowWidth.value <= BREAKPOINTS.medium)
  const isLarge = computed(() => windowWidth.value > BREAKPOINTS.medium && windowWidth.value <= BREAKPOINTS.large)
  const isXLarge = computed(() => windowWidth.value > BREAKPOINTS.large)

  return { windowWidth, isSmall, isMedium, isLarge, isXLarge }
}
