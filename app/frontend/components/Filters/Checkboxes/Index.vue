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
  // Avoids a redundant request when Clear is clicked on an empty group.
  if (!selected.value.length) return

  selected.value = []
  emitChange()
})

watch(() => props.preSelected, (value) => {
  selected.value = value ?? []
})

// Option ids can be numbers (Comfy::Cms::PageCategory#id) but always come back
// from the query string as strings, so compare by String(), not strict equality.
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

// Lets SearchAreas/CheckboxSearch.vue clear a hidden group on a tab switch
// without bumping resetKey, which would clear the visible group too.
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
