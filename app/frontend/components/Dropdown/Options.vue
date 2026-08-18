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

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-dropdown-options__options {
  @apply
  tw-shared-shadow-grey
  absolute
  left-0
  z-1
  mt-1
  min-w-[60%]
  max-h-80
  list-none
  overflow-y-auto
  ps-0;
}

.ct-dropdown-options__option {
  @apply
  bg-white
  p-3
  cursor-pointer
  tw-shared-font-hind-siliguri__light-base-grey-black;
}
</style>
