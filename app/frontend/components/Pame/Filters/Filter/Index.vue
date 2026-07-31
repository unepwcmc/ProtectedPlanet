<template>
  <li
    v-if="hasOptions"
    class="filter"
  >
    <p
      class="filter__button button"
      :class="{
        'filter__button--active': isOpen,
        'filter__button--has-selected': hasSelected,
        'button--disabled': pameStore.isFetching
      }"
      @click="onToggle"
    >
      {{ title }}
      <span
        v-show="hasSelected"
        class="filter__button-total"
        v-text="pendingOptions.length"
      />
    </p>

    <div
      class="filter__options"
      :class="[filterClass, { 'filter__options--active': isOpen }]"
    >
      <PameFiltersFilterOptions
        :options
        :selectedOptions="pendingOptions"
        :groupId="name"
        @click="onOptionClick"
      />

      <div class="filter__buttons">
        <button
          class="filter__button-clear"
          @click="onClear"
          v-text="'Clear'"
        />
        <button
          class="filter__button-cancel"
          @click="onCancel"
          v-text="'Cancel'"
        />
        <button
          class="filter__button-apply"
          :disabled="pameStore.isFetching"
          @click="onApply"
          v-text="'Apply'"
        />
      </div>
    </div>
  </li>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import PameFiltersFilterOptions from '@/components/Pame/Filters/Filter/Options.vue'
import { useAnalytics } from '@/composables/useAnalytics'
import { usePameStore } from '@/stores/usePameStore'

const { trackEvent } = useAnalytics()

const props = defineProps<{
  name: string
  title: string
  options: string[]
  isOpen: boolean
}>()

const emit = defineEmits<{
  toggle: []
  apply: [options: string[]]
}>()

const pameStore = usePameStore()

// `pendingOptions` mirrors the checkboxes as the user clicks them; `appliedOptions`
// is only updated on Apply, and Cancel reverts the checkboxes to it — same
// two-state model as the legacy DataFilter (`activeOptions`/live `$children`).
const pendingOptions = ref<string[]>([])
const appliedOptions = ref<string[]>([])

const hasOptions = computed(() => props.options.length > 0)
const hasSelected = computed(() => pendingOptions.value.length > 0)
const filterClass = computed(() => `filter__options--${props.name.replace(/[\s()_]/g, '-').toLowerCase()}`)

function onOptionClick(option: string, checked: boolean) {
  pendingOptions.value = checked
    ? [...pendingOptions.value, option]
    : pendingOptions.value.filter(selected => selected !== option)
}

function onToggle() {
  if (pameStore.isFetching) return
  emit('toggle')
}

function onCancel() {
  pendingOptions.value = [...appliedOptions.value]
  emit('toggle')
  trackEvent('click', { event_label: `Page: PAME - Filter title: ${props.title} - Button: cancel` })
}

function onClear() {
  pendingOptions.value = []
  trackEvent('click', { event_label: `Page: PAME - Filter title: ${props.title} - Button: clear` })
}

function onApply() {
  if (pameStore.isFetching) return

  appliedOptions.value = [...pendingOptions.value]
  emit('toggle')
  emit('apply', appliedOptions.value)
  trackEvent('click', { event_label: `Page: PAME - Filter title: ${props.title} - Button: Apply` })
}
</script>
