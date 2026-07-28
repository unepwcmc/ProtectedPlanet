<template>
  <li class="filter__option">
    <input
      :id="optionId"
      type="checkbox"
      class="filter__checkbox"
      :class="{ 'filter__checkbox--active': checked }"
      :checked
      @change="onChange"
    >
    <label
      :for="optionId"
      class="filter__checkbox-label"
      v-text="option"
    />
  </li>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  option: string
  checked: boolean
  groupId: string
}>()

const emit = defineEmits<{ click: [checked: boolean] }>()

const optionId = computed(() => `${props.groupId}-${props.option.replace(/[\s()_]/g, '-').toLowerCase()}`)

const onChange = (event: Event) => emit('click', (event.target as HTMLInputElement).checked)
</script>
