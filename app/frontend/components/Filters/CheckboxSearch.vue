<template>
  <div class="ct-filters-checkbox-search">
    <TabStrip
      :children="tabs"
      :gaId
      :preSelectedId="selectedTabId"
      @click:tab="updateSelectedTab"
    />
    <input
      v-model="searchTerm"
      class="ct-filters-checkbox-search__input"
      type="text"
      aria-label="Search filter options"
    >
    <FiltersCheckboxes
      :id
      ref="checkboxesEl"
      :gaId
      class="ct-filters-checkbox-search__options"
      :options="autocompleteOptions"
      :preSelected="preSelectedCheckboxes ?? undefined"
      :resetKey
      @update:options="updateSelectedCheckboxes"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import TabStrip from '@/components/TabStrip/Index.vue'
import FiltersCheckboxes from '@/components/Filters/Checkboxes/Index.vue'
import type { SearchFilterOption } from '@/types/backend'

const props = defineProps<{
  gaId?: string
  id: string
  options: SearchFilterOption[]
  preSelected?: { type: string, options: string[] }
  name: string
  resetKey?: number
}>()

const tabs = computed(() => props.options.map(option => ({ id: option.id, title: option.title })))

const defaultTabId = props.options[0].id
const preSelectedCheckboxes = ref<string[] | null>(props.preSelected?.options ?? null)
const selectedTabId = ref(props.preSelected?.type ?? defaultTabId)
const searchTerm = ref('')
const autocompleteOptions = computed(() => {
  let options = props.options.find(option => option.id === selectedTabId.value)?.autocomplete ?? []

  if (searchTerm.value !== '') {
    const regex = new RegExp(searchTerm.value, 'i')
    options = options.filter(option => option.title.match(regex))
  }

  return options
})
function reset() {
  preSelectedCheckboxes.value = null
  selectedTabId.value = defaultTabId
  searchTerm.value = ''
}
watch(() => props.resetKey, () => {
  reset()
})

const emit = defineEmits<{ 'update:options': [value: { type: string, options: string[] }] }>()
function updateSelectedCheckboxes(options: Array<string | number>) {
  emit('update:options', { type: selectedTabId.value, options: options as string[] })
}

const checkboxesEl = ref<InstanceType<typeof FiltersCheckboxes> | null>(null)
function updateSelectedTab(id: string) {
  reset()
  selectedTabId.value = id
  checkboxesEl.value?.reset()
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-filters-checkbox-search {
  @apply tw-shared-base-flex-col-gap-3;
}

.ct-filters-checkbox-search__input {
  @apply
  block
  w-full
  h-11.75
  mb-3.5
  rounded-[0.1875rem]
  border
  border-solid
  border-theme-grey
  px-2
  py-1.5
  font-sans
  text-lg
  text-theme-grey-black;
}

.ct-filters-checkbox-search__options {
  @apply
  overflow-y-auto
  max-h-62.5;
}
</style>
