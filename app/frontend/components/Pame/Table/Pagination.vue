<template>
  <div class="pagination right">
    <div
      v-if="hasResults"
      class="pagination__content"
    >
      <span class="bold">{{ firstItem }} - {{ lastItem }} of {{ totalItems }}</span>
      <button
        class="pagination__button--previous"
        :class="{ 'ct-pame-table-pagination__button--disabled': !isPreviousActive || pameStore.isFetching }"
        :disabled="!isPreviousActive || pameStore.isFetching"
        @click="onChangePage('previous')"
      />
      <button
        class="pagination__button--next"
        :class="{ 'ct-pame-table-pagination__button--disabled': !isNextActive || pameStore.isFetching }"
        :disabled="!isNextActive || pameStore.isFetching"
        @click="onChangePage('next')"
      />
    </div>
    <div
      v-else
      class="left"
    >
      <p>There are no records matching the selected filters</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { usePameStore } from '@/stores/usePameStore'

const props = defineProps<{
  currentPage: number
  itemsPerPage: number
  totalItems: number
  totalPages: number
}>()

const emit = defineEmits<{ requestItems: [] }>()

const pameStore = usePameStore()

const isNextActive = computed(() => props.currentPage < props.totalPages)
const isPreviousActive = computed(() => props.currentPage > 1)
const hasResults = computed(() => props.totalItems > 0)

const firstItem = computed(() => {
  if (props.totalItems === 0) return 0
  if (props.totalItems < props.itemsPerPage) return 1
  return props.itemsPerPage * (props.currentPage - 1) + 1
})

const lastItem = computed(() => Math.min(props.itemsPerPage * props.currentPage, props.totalItems))

function onChangePage(direction: 'previous' | 'next') {
  const isActive = direction === 'next' ? isNextActive.value : isPreviousActive.value
  if (!isActive || pameStore.isFetching) return

  const newPage = direction === 'next' ? props.currentPage + 1 : props.currentPage - 1
  pameStore.updateRequestedPage(newPage)
  emit('requestItems')
}
</script>
<style scoped lang="css">
@reference "#importtailwindcss";

.ct-pame-table-pagination__button--disabled {
  @apply tw-shared-button--disabled;
}
</style>
