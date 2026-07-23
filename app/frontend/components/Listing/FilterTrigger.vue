<template>
  <button
    class="filter__trigger"
    :class="{ disabled: isDisabled }"
    @click="toggle"
  >
    <span
      class="button__text"
      v-text="text"
    />
  </button>
</template>

<script setup lang="ts">
const props = defineProps<{ isDisabled?: boolean, text: string }>()
const emit = defineEmits<{ 'toggle:filterPane': [] }>()

function toggle() {
  if (props.isDisabled) return
  emit('toggle:filterPane')
}
</script>
