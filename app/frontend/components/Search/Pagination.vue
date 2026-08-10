<template>
  <div class="pagination">
    <div
      v-if="haveResults"
      class="pagination__content"
    >
      <span v-text="text" />
      <button
        :disabled="!previousIsActive || loading"
        :class="['pagination__button--previous', {
          'ct-search-pagination__button--disabled': !previousIsActive || loading }]"
        @click="changePage(previousIsActive, 'previous')"
      />
      <button
        :disabled="!nextIsActive || loading"
        :class="['pagination__button--next', {
          'ct-search-pagination__button--disabled': !nextIsActive || loading }]"
        @click="changePage(nextIsActive, 'next')"
      />
    </div>
    <p
      v-else
      class="pagination__no-results"
      v-html="noResultsText"
    />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  currentPage: number
  loading?: boolean
  noResultsText: string
  pageItemsEnd: number
  pageItemsStart: number
  totalItems: number
}>()

const text = computed(() => `${props.pageItemsStart} - ${props.pageItemsEnd} of ${props.totalItems}`)

const emit = defineEmits<{ 'update:page': [requestedPage: number] }>()

const haveResults = computed(() => props.totalItems > 0)
const nextIsActive = computed(() => props.pageItemsEnd < props.totalItems)
const previousIsActive = computed(() => props.currentPage > 1)

function changePage(isActive: boolean, direction: 'previous' | 'next') {
  if (!isActive || props.loading) return

  emit('update:page', direction === 'next' ? props.currentPage + 1 : props.currentPage - 1)
}
</script>
<style scoped lang="css">
@reference "#importtailwindcss";

.ct-search-pagination__button--disabled {
  @apply tw-shared-button--disabled;
}
</style>
