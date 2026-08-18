<template>
  <ul class="ct-filters-checkboxes">
    <FiltersCheckboxesItem
      v-for="option in options"
      :key="option.id"
      :checked="isSelected(option.id)"
      :groupId="id"
      :option
      @click="onClick(option, $event)"
    />
  </ul>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import useAnalytics from '@/composables/useAnalytics'
import FiltersCheckboxesItem from '@/components/Filters/Checkboxes/Item.vue'
import type { FilterOption } from '@/types/backend'

const { trackEvent } = useAnalytics()

const props = defineProps<{
  id: string
  gaId?: string
  options: FilterOption[]
  preSelected?: Array<string | number>
  resetKey?: number
}>()

const emit = defineEmits<{ 'update:options': [ids: Array<string | number>] }>()

const selected = ref<Array<string | number>>(props.preSelected ?? [])

watch(() => props.resetKey, () => {
  // Guards against firing a redundant search request when Clear is clicked
  // again on a group that's already empty.
  if (!selected.value.length) return

  selected.value = []
  emitChange()
})

watch(() => props.preSelected, (value) => {
  selected.value = value ?? []
})

// Filter option ids can be numbers (Comfy::Cms::PageCategory#id), but values
// round-tripped through the URL query string are always strings, so
// selection checks must compare by String() rather than strict equality.
function isSelected(id: string | number) {
  return selected.value.some(selectedId => String(selectedId) === String(id))
}

function onClick(option: FilterOption, checked: boolean) {
  selected.value = checked
    ? [...selected.value, option.id]
    : selected.value.filter(id => String(id) !== String(option.id))
  emitChange()
}

function selectedTitles() {
  return props.options
    .filter(option => isSelected(option.id))
    .map(option => option.title)
    .join(', ')
}

function emitChange() {
  emit('update:options', selected.value)

  if (props.gaId) {
    trackEvent('click', { event_label: `${props.gaId} - Checkbox(es): ${selectedTitles()}` })
  }
}

// Used by SearchAreas/CheckboxSearch.vue to clear a hidden filter group's
// selection when the user switches tabs, without bumping resetKey (which
// would also clear the visible group's own state).
function reset() {
  selected.value = []
}

defineExpose({ reset })
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-filters-checkboxes {
  @apply
  overflow-y-auto
  tw-shared-base-flex-col-gap-1;
}
</style>
