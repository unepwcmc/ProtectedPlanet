<template>
  <li class="ct-filters-checkboxes-item">
    <label
      :for="inputId"
      class="ct-filters-checkboxes-item__label"
      :class="{
        'ct-filters-checkboxes-item__label--active': checked
      }"
    >
      <input
        :id="inputId"
        type="checkbox"
        class="ct-filters-checkboxes-item__input"
        :checked
        :value="option.id"
        @change="onChange"
      >
      <span
        class="ct-filters-checkboxes-item__text"
        v-text="option.title"
      />
    </label>
  </li>
</template>

<script setup lang="ts">
import { useId } from 'vue'
import type { FilterOption } from '@/types/backend'

const props = defineProps<{
  checked: boolean
  groupId: string
  option: FilterOption
}>()

// The desktop and mobile filter panels render the same options
// simultaneously (visibility toggled by CSS), so a plain groupId+title id
// would collide across the two trees and mis-associate label clicks.
const inputId = `${props.groupId}-${props.option.title}-${useId()}`

const emit = defineEmits<{ click: [checked: boolean] }>()
function onChange() {
  emit('click', !props.checked)
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-filters-checkboxes-item {
  @apply flex;
}

.ct-filters-checkboxes-item__label {
  @apply
  flex
  items-center
  tw-shared-border-grey-light
  tw-shared-border-radius
  bg-white
  min-h-8
  px-1.5
  py-2.5
  w-full
  cursor-pointer;
}

.ct-filters-checkboxes-item__label--active {
  @apply
  bg-theme-primary
  outline-none;
}

.ct-filters-checkboxes-item__text {
  @apply tw-shared-font-hind-siliguri__light-sm;
}

.ct-filters-checkboxes-item__input {
  @apply sr-only;
}
</style>
