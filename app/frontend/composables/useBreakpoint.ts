// Reactive viewport breakpoint, for the two components whose mobile and desktop
// variants are different enough to be separate SFCs rather than one responsive
// tree (Filters/Panel, Pame/Filters/Filter). Each caller gets its own resize
// listener — negligible for two components.
//
// The thresholds are Tailwind's `md` (768) and `lg` (1024): `isSmall` is below
// md, `isMedium` is md up to and including lg. That upper bound is deliberately
// inclusive, so at exactly 1024px — `lg` in Tailwind's own scale — these
// components still render their mobile variant. Pre-existing behaviour, left
// alone: changing it would move which variant renders.
//
// NB `useMediaQuery` would notify only on threshold crossings rather than
// re-evaluating on every resize pixel, but jsdom's `matchMedia` stub always
// reports `matches: false`, which silently flips every spec that doesn't mock
// this module onto the desktop variant. Not worth a hand-rolled matchMedia
// emulator in the test setup for two components.
import { computed } from 'vue'
import { useWindowSize } from '@vueuse/core'

const BREAKPOINTS = { small: 767, medium: 1024 }

export default function () {
  const { width: windowWidth } = useWindowSize()

  const isSmall = computed(() => windowWidth.value <= BREAKPOINTS.small)
  const isMedium = computed(() => windowWidth.value > BREAKPOINTS.small && windowWidth.value <= BREAKPOINTS.medium)

  return { isSmall, isMedium }
}
