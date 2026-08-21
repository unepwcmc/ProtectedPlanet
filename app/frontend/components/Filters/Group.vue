<template>
  <li class="ct-filters-group">
    <div class="ct-filters-group__header">
      <h4
        v-if="title"
        class="ct-filters-group__title"
        v-text="title"
      />
      <button
        class="ct-filters-group__clear"
        @click="clear"
      >
        <span v-text="textClear" />
        <span class="ct-filters-group__clear-icon">
          <IconClose class="ct-filters-group__clear-icon-svg" />
        </span>
      </button>
    </div>
    <FiltersCheckboxes
      v-if="type === 'checkbox'"
      :id
      class="ct-filters-group__options"
      :gaId="gaIdWithFilter"
      :options
      :preSelected="preSelectedIds"
      :resetKey="combinedResetKey"
      @update:options="onUpdateCheckboxes"
    />
    <FiltersRadioButtons
      v-else-if="type === 'radio'"
      :id
      class="ct-filters-group__options"
      :gaId="gaIdWithFilter"
      :name="name ?? id"
      :options="searchOptions"
      :resetKey="combinedResetKey"
      @update:options="onUpdateRadio"
    />
    <FiltersCheckboxSearch
      v-else-if="type === 'checkbox-search'"
      :id
      :gaId="gaIdWithFilter"
      :name="name ?? id"
      :options="searchOptions"
      :preSelected="preSelectedCheckboxSearch"
      :resetKey="combinedResetKey"
      @update:options="onUpdateCheckboxSearch"
    />
  </li>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import FiltersCheckboxes from '@/components/Filters/Checkboxes/Index.vue'
import FiltersCheckboxSearch from '@/components/Filters/CheckboxSearch.vue'
import FiltersRadioButtons from '@/components/Filters/RadioButtons.vue'
import IconClose from '@/components/Icon/Close.vue'
import type { FilterGroupFilter, FilterGroupSelection, FilterOption, SearchFilterOption } from '@/types/backend'

const props = defineProps<{
  id: string
  gaId?: string
  name?: string
  options: FilterOption[]
  preSelected?: FilterGroupFilter['preSelected']
  resetKey?: number
  textClear: string
  title?: string
  type: FilterGroupFilter['type']
}>()

const emit = defineEmits<{ 'update:filter': [payload: { id: string, options: FilterGroupSelection }] }>()

const localResetKey = ref(0)

// Clear empties this group alone, but a page can also reset every group at once
// (SearchAreas does on a new search), so the two counters are summed instead of
// one overwriting the other.
const combinedResetKey = computed(() => localResetKey.value + (props.resetKey ?? 0))

const gaIdWithFilter = computed(() => `${props.gaId} - Filter title: ${props.title}`)

// Radio and checkbox-search groups only ever come from
// Search::FiltersSerializer, which sends string ids and — for checkbox-search —
// the nested `autocomplete` lists. Numeric ids come from the CMS listing, and
// that sends checkbox groups exclusively.
const searchOptions = computed(() => props.options as SearchFilterOption[])

const hasPreSelected = computed(() => Array.isArray(props.preSelected) && props.preSelected.length > 0)

// Both shapes arrive as an array: checkbox and radio groups hold option ids,
// a checkbox-search group holds a single {type, options} entry.
const preSelectedIds = computed(() => (
  hasPreSelected.value ? props.preSelected as Array<string | number> : undefined
))

const preSelectedCheckboxSearch = computed(() => (
  hasPreSelected.value ? props.preSelected![0] as { type: string, options: string[] } : undefined
))

function clear() {
  localResetKey.value += 1
}

function emitFilter(options: FilterGroupSelection) {
  emit('update:filter', { id: props.id, options })
}

function onUpdateCheckboxes(options: Array<string | number>) {
  emitFilter(options)
}

// RadioButtons emits the bare id, or '' once cleared; the endpoint expects the
// same array shape as every other filter type.
function onUpdateRadio(option: string) {
  emitFilter(option ? [option] : [])
}

function onUpdateCheckboxSearch(value: { type: string, options: string[] }) {
  emitFilter(value)
}

// Primes the parent's active-filter state from a URL-preselected value.
onMounted(() => {
  if (!hasPreSelected.value) return

  if (props.type === 'checkbox-search') emitFilter(preSelectedCheckboxSearch.value!)
  else emitFilter(preSelectedIds.value!)
})
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-filters-group {
  @apply tw-shared-base-flex-col-gap-3;
}

.ct-filters-group__header {
  @apply
  flex
  justify-between
  items-center;
}

.ct-filters-group__title {
  @apply tw-shared-font-hind-siliguri__semibold-lg-lg-base-grey-black;
}

.ct-filters-group__clear {
  @apply
  tw-shared-button-basic
  flex
  items-center
  tw-shared-font-hind-siliguri__light-sm
  tw-shared-base-flex-gap-2;
}

.ct-filters-group__clear-icon {
  @apply
  flex
  items-center
  justify-center
  p-1
  rounded-full
  bg-black;
}

.ct-filters-group__clear-icon-svg {
  @apply
  size-2
  text-white;
}

.ct-filters-group__options {
  @apply
  overflow-y-auto
  max-h-62.5
  tw-shared-font-hind-siliguri__light-sm;
}
</style>
