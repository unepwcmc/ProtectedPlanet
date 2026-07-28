<template>
  <div class="ct-dropdown">
    <span
      class="ct-dropdown__title"
      v-text="title"
    />
    <div
      ref="rootEl"
      class="ct-dropdown__container"
    >
      <button
        class="ct-dropdown__button"
        @click="toggle"
      >
        <span
          class="ct-dropdown__chosen-value"
          v-text="modelValue ?? defaultDropdownText"
        />
        <IconArrow class="ct-dropdown__icon" />
      </button>
      <DropdownOptions
        v-if="openOptions"
        :options
        @click="chooseOption"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import IconArrow from '@/components/Icon/Arrow.vue'
import DropdownOptions from '@/components/Dropdown/Options.vue'
import { usePopupCloseListeners } from '@/composables/usePopupCloseListeners'

defineProps<{
  title?: string
  defaultDropdownText?: string
  options: string[]
}>()

const modelValue = defineModel<string>()

const rootEl = ref<HTMLElement | null>(null)
const openOptions = ref(false)

function chooseOption(option: string) {
  modelValue.value = option
  openOptions.value = false
}

function toggle() {
  openOptions.value = !openOptions.value
}

usePopupCloseListeners(rootEl, {
  isActive: openOptions,
  onClose: () => { openOptions.value = false }
})
</script>
