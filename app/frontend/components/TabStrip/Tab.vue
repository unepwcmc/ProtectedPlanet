<template>
  <li
    class="ct-tab-strip-tab"
    :class="[
      `ct-tab-strip-tab--${size}`,
      {
        'ct-tab-strip-tab--active': isActive,
        'ct-tab-strip-tab--disabled': disabled
      }
    ]"
    :aria-disabled="disabled"
    @click="click"
    v-text="title"
  />
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(defineProps<{
  id: string
  selectedId: string
  title: string
  disabled?: boolean
  size?: 'default' | 'small'
}>(), {
  size: 'default'
})

const emit = defineEmits<{ 'click:tab': [id: string] }>()

const isActive = computed(() => props.id === props.selectedId)

function click() {
  if (props.disabled) return
  emit('click:tab', props.id)
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-tab-strip-tab {
  @apply
  tw-shared-button-basic
  shrink-0
  rounded-full
  border
  border-solid
  border-transparent
  hover:border-theme-primary;
}

.ct-tab-strip-tab--default {
  @apply
  tw-shared-font-family-hind-siliguri__leading-1-3-grey-black
  font-light
  text-lg
  md:text-xl
  px-6.5
  py-1.25;
}

.ct-tab-strip-tab--small {
  @apply
  tw-shared-font-family-hind-siliguri__leading-1-3-grey-black
  font-light
  text-sm
  px-4
  py-1.5;
}

.ct-tab-strip-tab--active {
  @apply
  border-theme-primary
  bg-theme-primary
  text-white;
}

.ct-tab-strip-tab--disabled {
  @apply
  text-theme-grey
  cursor-not-allowed;
}
</style>
