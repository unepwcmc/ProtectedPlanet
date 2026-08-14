<template>
  <div class="ct-listing-filter-group">
    <div class="ct-listing-filter-group__header">
      <h4
        v-if="filter.title"
        class="ct-listing-filter-group__title"
        v-text="filter.title"
      />
      <button
        class="ct-listing-filter-group__clear"
        @click="clear"
      >
        <span v-text="textClear" />
        <span class="ct-listing-filter-group__clear-icon">
          <IconClose class="ct-listing-filter-group__clear-icon-svg" />
        </span>
      </button>
    </div>
    <FiltersCheckboxes
      :id="filter.id"
      :gaId="gaIdWithFilter"
      :options="filter.options"
      :preSelected
      :resetKey
      @update:options="onUpdate"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import FiltersCheckboxes from '@/components/Filters/Checkboxes/Index.vue'
import IconClose from '@/components/Icon/Close.vue'
import type { ListingFilter } from '@/types/backend'

const props = defineProps<{
  filter: ListingFilter
  gaId?: string
  preSelected?: Array<string | number>
  textClear: string
}>()

const emit = defineEmits<{ 'update:filter': [payload: { id: string, options: Array<string | number> }] }>()

const resetKey = ref(0)
const gaIdWithFilter = computed(() => `${props.gaId} - Filter title: ${props.filter.title}`)

function clear() {
  resetKey.value++
}

function onUpdate(options: Array<string | number>) {
  emit('update:filter', { id: props.filter.id, options })
}

// Primes the parent's active-filter state from a URL-preselected value, same
// as the legacy vFilter component's `created()` hook.
onMounted(() => {
  if (props.preSelected?.length) onUpdate(props.preSelected)
})
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-listing-filter-group {
  @apply tw-shared-base-flex-col-gap-3;
}

.ct-listing-filter-group__header {
  @apply
  flex
  justify-between
  items-center;
}

.ct-listing-filter-group__title {
  @apply tw-shared-font-hind-siliguri__semibold-lg-lg-base-grey-black;
}

.ct-listing-filter-group__clear {
  @apply
  tw-shared-button-basic
  flex
  items-center
  tw-shared-font-hind-siliguri__light-sm
  tw-shared-base-flex-gap-2;
}

.ct-listing-filter-group__clear-icon {
  @apply
  flex
  items-center
  justify-center
  p-1
  rounded-full
  bg-black;
}

.ct-listing-filter-group__clear-icon-svg {
  @apply
  size-2
text-white;
}
</style>
