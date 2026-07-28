<template>
  <ul class="ct-dropdown-options__options">
    <li
      v-for="(option, index) in options"
      :key="`${index}ct-dropdown-options`"
      class="ct-dropdown-options__option"
      @click="chooseOption(option)"
      v-text="option"
    />
  </ul>
</template>

<script setup lang="ts">
defineProps<{ options: string[] }>()
const emit = defineEmits<{ click: [option: string] }>()

function chooseOption(option: string) {
  emit('click', option)
}
</script>
