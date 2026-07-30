<template>
  <li
    class="tab__trigger"
    :class="{
      active: isActive,
      'ct-tab-strip-tab--disabled': disabled
    }"
    :aria-disabled="disabled"
    @click="click"
    v-text="title"
  />
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  id: string
  selectedId: string
  title: string
  disabled?: boolean
}>()

const emit = defineEmits<{ 'click:tab': [id: string] }>()

const isActive = computed(() => props.id === props.selectedId)

function click() {
  if (props.disabled) return
  emit('click:tab', props.id)
}
</script>

<style scoped lang="css">
@reference "tailwindcss";

.ct-tab-strip-tab--disabled {
  @apply text-theme-grey cursor-not-allowed;
}
</style>
