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
    role="tab"
    :aria-selected="isActive"
    :aria-disabled="disabled"
    :tabindex="disabled ? -1 : 0"
    @click="click"
    @keydown.enter.prevent="click"
    @keydown.space.prevent="click"
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
  tw-shared-font-hind-siliguri__light-lg-md-xl-grey-black
  px-6.5
  py-1.25;
}

.ct-tab-strip-tab--small {
  @apply
  tw-shared-font-hind-siliguri__light-sm-grey-black
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
