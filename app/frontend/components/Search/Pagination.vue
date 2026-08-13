<template>
  <div
    v-if="haveResults"
    class="ct-search-pagination"
  >
    <span
      class="ct-search-pagination__text"
      v-text="text"
    />
    <button
      class="ct-search-pagination__button
      ct-search-pagination__button--previous"
      :class="{ 'ct-search-pagination__button--disabled': isPreviousDisabled }"
      :disabled="isPreviousDisabled"
      @click="changePage(previousIsActive, 'previous')"
    >
      <IconCircleChevron
        direction="left"
        circleColor="green"
        class="ct-search-pagination__icon"
      />
    </button>
    <button
      class="ct-search-pagination__button
      ct-search-pagination__button--next"
      :class="{ 'ct-search-pagination__button--disabled': isNextDisabled }"
      :disabled="isNextDisabled"
      @click="changePage(nextIsActive, 'next')"
    >
      <IconCircleChevron
        circleColor="green"
        class="ct-search-pagination__icon"
      />
    </button>
  </div>
  <p
    v-else
    class="ct-search-pagination__no-results"
    v-html="noResultsText"
  />
</template>

<script setup lang="ts">
import { computed } from 'vue'
import IconCircleChevron from '@/components/Icon/CircleChevron.vue'

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
const isNextDisabled = computed(() => !nextIsActive.value || props.loading)
const isPreviousDisabled = computed(() => !previousIsActive.value || props.loading)

function changePage(isActive: boolean, direction: 'previous' | 'next') {
  if (!isActive || props.loading) return

  emit('update:page', direction === 'next' ? props.currentPage + 1 : props.currentPage - 1)
}
</script>
<style scoped lang="css">
@reference "#importtailwindcss";

.ct-search-pagination {
  @apply
  tw-shared-base-flex-gap-3
  justify-end
  items-center;
}

.ct-search-pagination__text {
  @apply tw-shared-font-hind-siliguri__light-base-lg-lg;
}

.ct-search-pagination__button {
  @apply
  inline-flex
  items-center
  justify-center
  border-none
  cursor-pointer
  no-underline
  outline-none;
}

.ct-search-pagination__button--disabled {
  @apply tw-shared-button--disabled;
}

.ct-search-pagination__icon {
  @apply size-8.5;
}

.ct-search-pagination__no-results {
  @apply tw-shared-font-hind-siliguri__normal-lg-md-xl-grey-dark
  text-center
  my-15;
}
</style>
