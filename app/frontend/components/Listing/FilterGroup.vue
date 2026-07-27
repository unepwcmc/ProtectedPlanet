<template>
  <div class="filter">
    <div class="filter__header">
      <h4
        v-if="filter.title"
        class="filter__title"
        v-text="filter.title"
      />
      <button
        class="filter__button-clear"
        @click="clear"
        v-text="textClear"
      />
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
