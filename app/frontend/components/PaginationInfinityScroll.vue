<template>
  <span
    v-show="showTrigger"
    ref="triggerEl"
    :class="triggerClass"
  />
</template>

<script setup lang="ts">
// Replaces the legacy `scrollmagic` dependency with a native IntersectionObserver
// (same approach as Counter.vue), observing this component's own root instead of a
// separate `document.querySelector(smTriggerElement)` lookup.
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'

const props = withDefaults(defineProps<{
  triggerClass?: string
  total?: number
  totalPages?: number
  resetKey?: number
}>(), {
  triggerClass: 'ct-pagination-infinity-scroll__trigger',
  total: 0,
  totalPages: 0,
  resetKey: 0
})

const emit = defineEmits<{ requestMore: [page: number] }>()

const triggerEl = ref<HTMLElement | null>(null)
const currentPage = ref(1)

const showTrigger = computed(() => currentPage.value < props.totalPages)

function requestMore() {
  currentPage.value += 1
  emit('requestMore', currentPage.value)
}

function reset() {
  currentPage.value = 1
}

watch(() => props.resetKey, reset)

let observer: IntersectionObserver | undefined

onMounted(() => {
  if (!triggerEl.value) return

  observer = new IntersectionObserver((entries) => {
    if (showTrigger.value && entries.some(entry => entry.isIntersecting)) {
      requestMore()
    }
  })
  observer.observe(triggerEl.value)
})

onUnmounted(() => {
  observer?.disconnect()
})
</script>
