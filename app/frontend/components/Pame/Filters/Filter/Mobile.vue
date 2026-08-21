<template>
  <div
    class="ct-pame-filter-mobile"
    :class="[filterClass, { 'ct-pame-filter-mobile--active': isOpen }]"
  >
    <PameFiltersFilterOptions
      :options
      :selectedOptions="pendingOptions"
      :groupId="name"
      class="ct-pame-filter-mobile__options"
      @click="onOptionClick"
    />
    <div class="ct-pame-filter-mobile__buttons">
      <button
        class="ct-pame-filter-mobile__button-clear"
        @click="onClear"
        v-text="'Clear'"
      />
      <div class="ct-pame-filter-mobile__buttons--right">
        <button
          class="ct-pame-filter-mobile__button-cancel"
          @click="onCancel"
          v-text="'Cancel'"
        />
        <button
          class="ct-pame-filter-mobile__button-apply"
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
import useFreezeBackground from '@/composables/useFreezeBackground'

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

useFreezeBackground(computed(() => props.isOpen))

// Seeded from `appliedOptions` (sourced from the URL) rather than empty:
// Filter/Index.vue's `v-if="isOpen"` recreates this on every open, so a fresh
// mount is the only place it can pick up the filter's current value.
const pendingOptions = ref<string[]>([...props.appliedOptions])

const filterClass = computed(() => `ct-pame-filter-mobile--${props.name.replace(/[\s()_]/g, '-').toLowerCase()}`)

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

.ct-pame-filter-mobile {
  @apply
  invisible
  fixed
  inset-0
  z-1
  h-screen
  w-full
  bg-white
  py-7.5
  px-6.25
  text-base
  tw-shared-base-flex-col-gap-3
  justify-between;
}

.ct-pame-filter-mobile--active {
  @apply visible;
}

.ct-pame-filter-mobile__buttons {
  @apply
  flex
  justify-between;
}

.ct-pame-filter-mobile__buttons--right {
  @apply tw-shared-base-flex-gap-3;
}

.ct-pame-filter-mobile__button-apply {
  @apply tw-shared-button--theme-purple;
}

.ct-pame-filter-mobile__button-cancel {
  @apply
  tw-shared-button--outline-black
  mx-auto;
}

.ct-pame-filter-mobile__button-clear {
  @apply tw-shared-button--outline-black;
}
</style>
