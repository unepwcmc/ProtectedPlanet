<template>
  <div
    class="ct-pame-filter__options"
    :class="[filterClass, { 'ct-pame-filter__options--active': isOpen }]"
  >
    <PameFiltersFilterOptions
      :options
      :selectedOptions="pendingOptions"
      :groupId="name"
      @click="onOptionClick"
    />
    <div class="ct-pame-filter__buttons">
      <button
        class="ct-pame-filter__button-clear"
        @click="onClear"
        v-text="'Clear'"
      />
      <div class="ct-pame-filter__buttons--right">
        <button
          class="ct-pame-filter__button-cancel"
          @click="onCancel"
          v-text="'Cancel'"
        />
        <button
          class="ct-pame-filter__button-apply"
          :disabled="isFetching"
          @click="onApply"
          v-text="'Apply'"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import PameFiltersFilterOptions from '@/components/Pame/Filters/Filter/Options.vue'
import useAnalytics from '@/composables/useAnalytics'

const { trackEvent } = useAnalytics()

const props = defineProps<{
  name: string
  title: string
  options: string[]
  appliedOptions: string[]
  isFetching: boolean
  isOpen: boolean
}>()

const emit = defineEmits<{
  toggle: []
  apply: [options: string[]]
}>()

// Seeded from `appliedOptions` (ultimately sourced from the URL, see
// Pame/Table/Index.vue) rather than an empty array — this component is
// destroyed and recreated every time its dropdown opens (see the
// `v-if="isOpen"` in Filter/Index.vue), so a fresh mount is the only place
// this can pick up the filter's real current value.
const pendingOptions = ref<string[]>([...props.appliedOptions])

const filterClass = computed(() => `ct-pame-filter__options--${props.name.replace(/[\s()_]/g, '-').toLowerCase()}`)

function onOptionClick(option: string, checked: boolean) {
  pendingOptions.value = checked
    ? [...pendingOptions.value, option]
    : pendingOptions.value.filter(selected => selected !== option)
}

function onCancel() {
  pendingOptions.value = [...props.appliedOptions]
  emit('toggle')
  trackEvent('click', { event_label: `Page: PAME - Filter title: ${props.title} - Button: cancel` })
}

function onClear() {
  pendingOptions.value = []
  trackEvent('click', { event_label: `Page: PAME - Filter title: ${props.title} - Button: clear` })
}

function onApply() {
  if (props.isFetching) return

  emit('toggle')
  emit('apply', [...pendingOptions.value])
  trackEvent('click', { event_label: `Page: PAME - Filter title: ${props.title} - Button: Apply` })
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-pame-filter__options {
  @apply
  invisible
  absolute
  z-1
  bg-white
  py-7.5
  px-6.25
  h-auto
  w-auto
  min-w-115
  mt-2
  border
border-black
  tw-shared-border-radius
  tw-shared-base-flex-col-gap-3;
}

.ct-pame-filter__options--active {
  @apply visible;
}

.ct-pame-filter__options--country {
  @apply max-w-120;
}

.ct-pame-filter__buttons {
  @apply
  flex
  justify-between;
}

.ct-pame-filter__buttons--right {
  @apply tw-shared-base-flex-gap-3;
}

.ct-pame-filter__button-apply {
  @apply tw-shared-button--theme-purple;
}

.ct-pame-filter__button-cancel {
  @apply
  tw-shared-button--outline-black
  mx-auto;
}

.ct-pame-filter__button-clear {
  @apply tw-shared-button--outline-black;
}
</style>
