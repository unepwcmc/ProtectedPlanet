<template>
  <ul class="filter__options flex flex-wrap flex-column list-none ps-0">
    <ListingCheckboxesItem
      v-for="option in options"
      :key="option.id"
      :checked="selected.includes(option.id)"
      :groupId="id"
      :option
      @change="onItemChange(option, $event)"
    />
  </ul>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import { trackEvent } from '@/lib/analytics'
import ListingCheckboxesItem from '@/components/Listing/Checkboxes/Item.vue'
import type { ListingFilterOption } from '@/types/backend'

const props = defineProps<{
  id: string
  gaId?: string
  options: ListingFilterOption[]
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

function onItemChange(option: ListingFilterOption, checked: boolean) {
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
</script>
