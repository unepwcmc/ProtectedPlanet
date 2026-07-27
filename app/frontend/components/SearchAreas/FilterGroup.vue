<template>
  <div class="filter">
    <div class="filter__header">
      <h4
        v-if="title"
        class="filter__title"
        v-text="title"
      />
      <button
        class="filter__button-clear"
        @click="clear"
        v-text="textClear"
      />
    </div>

    <FiltersCheckboxes
      v-if="type === 'checkbox'"
      :id
      :gaId="gaIdWithFilter"
      :options
      :preSelected="preSelectedArray"
      :resetKey="combinedResetKey"
      @update:options="updateFilter"
    />
    <div
      v-if="type === 'radio'"
      class="filter__options"
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
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import FiltersCheckboxes from '@/components/Filters/Checkboxes/Index.vue'
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
