<template>
  <div class="ct-dropdown-base">
    <span
      class="ct-dropdown-base__title"
      v-text="title"
    />
    <div
      ref="rootEl"
      class="ct-dropdown-base__container"
    >
      <button
        class="ct-dropdown-base__button"
        aria-haspopup="listbox"
        :aria-expanded="isOptionsOpen"
        @click="toggle"
      >
        <span
          class="ct-dropdown-base__chosen-value"
          v-text="modelValue ?? defaultDropdownText"
        />
        <IconArrow class="ct-dropdown-base__icon" />
      </button>
      <DropdownOptions
        v-if="isOptionsOpen"
        :options
        :selected="modelValue"
        @click="chooseOption"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import IconArrow from '@/components/Icon/Arrow.vue'
import DropdownOptions from '@/components/Dropdown/Options.vue'
import usePopupCloseListeners from '@/composables/usePopupCloseListeners'

defineProps<{
  title?: string
  defaultDropdownText?: string
  options: string[]
}>()

const modelValue = defineModel<string>()

const rootEl = ref<HTMLElement | null>(null)
const isOptionsOpen = ref(false)

function chooseOption(option: string) {
  modelValue.value = option
  isOptionsOpen.value = false
}

function toggle() {
  isOptionsOpen.value = !isOptionsOpen.value
}

usePopupCloseListeners(rootEl, {
  isActive: isOptionsOpen,
  onClose: () => { isOptionsOpen.value = false }
})
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-dropdown-base {
  @apply
  tw-shared-base-flex-col-gap-1
  w-full;
}

.ct-dropdown-base__title {
  @apply tw-shared-font-hind-siliguri__semibold-base-grey-black;
}

.ct-dropdown-base__container {
  @apply relative;
}

.ct-dropdown-base__button {
  @apply
  tw-shared-button--border-theme-primary
  items-center;
}

.ct-dropdown-base__chosen-value {
  @apply tw-shared-font-hind-siliguri__light-base-grey-black;
}

.ct-dropdown-base__icon {
  @apply w-2;
}
</style>
