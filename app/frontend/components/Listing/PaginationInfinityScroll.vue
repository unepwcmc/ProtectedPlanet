<template>
  <span
    v-show="showTrigger"
    ref="triggerEl"
    class="pagination__infinity-trigger"
  />
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'

const props = defineProps<{
  resetKey: number
  total?: number
  totalPages?: number
}>()

const emit = defineEmits<{ requestMore: [page: number] }>()

const currentPage = ref(1)
const triggerEl = ref<HTMLElement | null>(null)
let observer: IntersectionObserver | null = null

// v-show hides the trigger with display:none once the last page is reached,
// which IntersectionObserver naturally never reports as intersecting — so,
// unlike the legacy ScrollMagic scene, there's no need to add/remove the
// observer as pages load.
const showTrigger = computed(() => currentPage.value < (props.totalPages ?? 0))

function requestMore() {
  currentPage.value++
  emit('requestMore', currentPage.value)
}

watch(() => props.resetKey, () => {
  currentPage.value = 1
})

onMounted(() => {
  if (!triggerEl.value) return

  observer = new IntersectionObserver((entries) => {
    if (entries[0]?.isIntersecting) requestMore()
  })
  observer.observe(triggerEl.value)
})

onBeforeUnmount(() => observer?.disconnect())
</script>
