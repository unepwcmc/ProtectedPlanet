<template>
  <div
    v-if="hasResults"
    class="ct-pame-table-pagination"
  >
    <span
      class="ct-pame-table-pagination__text"
      v-text="`${firstItem} - ${lastItem} of ${totalItems}`"
    />
    <button
      class="ct-pame-table-pagination__button
      ct-pame-table-pagination__button--previous"
      :class="{ 'ct-pame-table-pagination__button--disabled': isPreviousDisabled }"
      :disabled="isPreviousDisabled"
      @click="onChangePage('previous')"
    >
      <IconCircleChevron
        direction="left"
        circleColor="green"
        class="ct-pame-table-pagination__icon"
      />
    </button>
    <button
      class="ct-pame-table-pagination__button
      ct-pame-table-pagination__button--next"
      :class="{ 'ct-pame-table-pagination__button--disabled': isNextDisabled }"
      :disabled="isNextDisabled"
      @click="onChangePage('next')"
    >
      <IconCircleChevron
        circleColor="green"
        class="ct-pame-table-pagination__icon"
      />
    </button>
  </div>
  <p
    v-else
    class="ct-pame-table-pagination__no-results"
    v-text="'There are no records matching the selected filters'"
  />
</template>

<script setup lang="ts">
import { computed } from 'vue'
import IconCircleChevron from '@/components/Icon/CircleChevron.vue'
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
const isNextDisabled = computed(() => !isNextActive.value || pameStore.isFetching)
const isPreviousDisabled = computed(() => !isPreviousActive.value || pameStore.isFetching)

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

.ct-pame-table-pagination {
  @apply
  tw-shared-base-flex-gap-3
  justify-end
  items-center;
}

.ct-pame-table-pagination__text {
  @apply tw-shared-font-hind-siliguri__normal-base-lg-lg-grey-black;
}

.ct-pame-table-pagination__button {
  @apply
  flex
  items-center
  justify-center
  border-none
  cursor-pointer
  no-underline
  outline-none;
}

.ct-pame-table-pagination__button--disabled {
  @apply tw-shared-button--disabled;
}

.ct-pame-table-pagination__icon {
  @apply size-8.5;
}

.ct-pame-table-pagination__no-results {
  @apply
  tw-shared-font-hind-siliguri__normal-lg-md-xl-grey-dark
  text-center
  my-15;
}
</style>
