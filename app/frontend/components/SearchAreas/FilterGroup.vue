<template>
  <li class="ct-search-areas-filter-group">
    <div class="ct-search-areas-filter-group__header">
      <h4
        class="ct-search-areas-filter-group__title"
        v-text="title"
      />
      <button
        class="ct-search-areas-filter-group__clear"
        @click="clear"
      >
        <span v-text="textClear" />
        <span class="ct-search-areas-filter-group__clear-icon">
          <IconClose class="ct-search-areas-filter-group__clear-icon-svg" />
        </span>
      </button>
    </div>

    <FiltersCheckboxes
      v-if="type === 'checkbox'"
      :id
      class="ct-search-areas-filter-group__options"
      :gaId="gaIdWithFilter"
      :options
      :preSelected="preSelectedArray"
      :resetKey="combinedResetKey"
      @update:options="updateFilter"
    />
    <div
      v-if="type === 'radio'"
      class="ct-search-areas-filter-group__options"
    >
      <SearchAreasRadioButtons
        :id
        :gaId="gaIdWithFilter"
        :name="name ?? id"
        :options
        :resetKey="combinedResetKey"
        @update:options="updateFilter"
      />
    </div>
    <SearchAreasCheckboxSearch
      v-if="type === 'checkbox-search'"
      :id
      :gaId="gaIdWithFilter"
      :name="name ?? id"
      :options
      :preSelected="preSelectedCheckboxSearch"
      :resetKey="combinedResetKey"
      @update:options="updateFilter"
    />
  </li>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import FiltersCheckboxes from '@/components/Filters/Checkboxes/Index.vue'
import IconClose from '@/components/Icon/Close.vue'
import SearchAreasRadioButtons from '@/components/SearchAreas/RadioButtons.vue'
import SearchAreasCheckboxSearch from '@/components/SearchAreas/CheckboxSearch.vue'
import type { SearchFilter, SearchFilterOption } from '@/types/backend'

const props = defineProps<{
  id: string
  gaId?: string
  name?: string
  options: SearchFilterOption[]
  preSelected?: SearchFilter['preSelected']
  title?: string
  textClear?: string
  type: 'checkbox' | 'radio' | 'checkbox-search'
  resetKey?: number
}>()

const emit = defineEmits<{ 'update:filter': [value: { id: string, options: unknown }] }>()

const localResetKey = ref(0)
const combinedResetKey = computed(() => localResetKey.value + (props.resetKey ?? 0))

const preSelectedArray = computed(() => (
  Array.isArray(props.preSelected) ? props.preSelected as string[] : undefined
))

const preSelectedCheckboxSearch = computed(() => (
  Array.isArray(props.preSelected) && props.preSelected.length ? props.preSelected[0] as { type: string, options: string[] } : undefined
))

const gaIdWithFilter = computed(() => `${props.gaId} - Filter title: ${props.title}`)

function clear() {
  localResetKey.value += 1
}

function updateFilter(updatedOptions: unknown) {
  let options = updatedOptions

  if (props.type === 'radio') {
    options = updatedOptions ? [updatedOptions] : []
  }

  emit('update:filter', { id: props.id, options })
}

// Primes the parent's active-filter state from a URL-preselected value, same
// as the legacy vFilter component's `created()` hook.
onMounted(() => {
  if (props.preSelected) {
    const preselected = props.type === 'checkbox-search' ? preSelectedCheckboxSearch.value : preSelectedArray.value
    updateFilter(preselected)
  }
})
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-search-areas-filter-group {
  @apply tw-shared-base-flex-col-gap-3;
}

.ct-search-areas-filter-group__header {
  @apply
  flex
  justify-between
  items-center;
}

.ct-search-areas-filter-group__title {
  @apply tw-shared-font-hind-siliguri__bold-lg-lg-base-grey-black;
}

.ct-search-areas-filter-group__clear {
  @apply
  tw-shared-button-basic
  flex
  items-center
  tw-shared-font-hind-siliguri__normal-sm
  tw-shared-base-flex-gap-2;
}

.ct-search-areas-filter-group__clear-icon {
  @apply
  flex
  items-center
  justify-center
  rounded-full
  p-1
  bg-black;
}

.ct-search-areas-filter-group__clear-icon-svg {
  @apply
  size-2
  text-white;
}

.ct-search-areas-filter-group__options {
  @apply
  overflow-y-auto
  max-h-62.5
  tw-shared-font-hind-siliguri__normal-sm;
}
</style>
