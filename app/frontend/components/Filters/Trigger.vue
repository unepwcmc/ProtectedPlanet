<template>
  <button
    class="filter__trigger"
    :class="{ disabled: isDisabled }"
    @click="toggleFilterPane"
  >
    <span
      class="button__text"
      v-text="text"
    />
  </button>
</template>

<script setup lang="ts">
const props = withDefaults(defineProps<{
  isDisabled?: boolean
  text: string
}>(), {
  isDisabled: false
})

const emit = defineEmits<{ 'toggle:filterPane': [] }>()

function toggleFilterPane() {
  if (props.isDisabled) return
  emit('toggle:filterPane')
}
</script>
