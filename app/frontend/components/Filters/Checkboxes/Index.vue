<template>
  <ul class="filter__options flex flex-column list-none ps-0">
    <FiltersCheckboxesItem
      v-for="option in options"
      :key="option.id"
      :checked="selected.includes(option.id)"
      :groupId="id"
      :option
      @click="onClick(option, $event)"
    />
  </ul>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import { trackEvent } from '@/lib/analytics'
import FiltersCheckboxesItem from '@/components/Filters/Checkboxes/Item.vue'
import type { FilterOption } from '@/types/backend'

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
  selected.value = []
  emitChange()
})

watch(() => props.preSelected, (value) => {
  selected.value = value ?? []
})

function onClick(option: FilterOption, checked: boolean) {
  selected.value = checked
    ? [...selected.value, option.id]
    : selected.value.filter(id => id !== option.id)

  emitChange()
}

function selectedTitles() {
  return props.options
    .filter(option => selected.value.includes(option.id))
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
