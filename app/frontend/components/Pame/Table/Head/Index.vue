<template>
  <thead
    ref="rootEl"
    class="ct-pame-table-head"
    :class="{ 'ct-pame-table-head--stuck': isSticky }"
  >
    <tr class="ct-pame-table-head__row">
      <PameTableHeadCell
        v-for="(filter, index) in filters"
        :key="`${filter.field}-${index}`"
        :filter
      />
    </tr>
  </thead>
</template>

<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from 'vue'
import PameTableHeadCell from '@/components/Pame/Table/Head/Cell.vue'
import type { PameTableAttribute } from '@/types/backend'

defineProps<{
  filters: PameTableAttribute[]
}>()

const rootEl = ref<HTMLElement | null>(null)
const isSticky = ref(false)
let stickyTrigger = 0
let visibilityObserver: IntersectionObserver | undefined

function setStickyTrigger() {
  if (!rootEl.value) return
  stickyTrigger = rootEl.value.clientHeight + rootEl.value.getBoundingClientRect().top + window.scrollY
}

function onScroll() {
  isSticky.value = window.scrollY > stickyTrigger
}

onMounted(() => {
  setStickyTrigger()
  onScroll()
  window.addEventListener('scroll', onScroll, { passive: true })
  window.addEventListener('resize', setStickyTrigger)

  // gdpame's tab_extras region (see partials/thematic_and_data_area/_tabs.html.erb)
  // is still legacy Vue2 `TabTarget` — a `display: none` toggle, not `v-if` — so
  // this table can mount while hidden and compute a 0-based trigger. Recompute once
  // the container actually gets a layout box, same fix as Map/Base.vue's `resize()`.
  if (rootEl.value && typeof IntersectionObserver !== 'undefined') {
    visibilityObserver = new IntersectionObserver((entries) => {
      if (entries[0]?.isIntersecting) setStickyTrigger()
    })
    visibilityObserver.observe(rootEl.value)
  }
})

onBeforeUnmount(() => {
  window.removeEventListener('scroll', onScroll)
  window.removeEventListener('resize', setStickyTrigger)
  visibilityObserver?.disconnect()
})
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-pame-table-head {
  @apply
  hidden
  xl:table-header-group
  h-14;
}

.ct-pame-table-head--stuck {
  @apply
  sticky
  top-0
  z-2;
}
</style>
