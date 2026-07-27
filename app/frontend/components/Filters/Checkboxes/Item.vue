<template>
  <li class="checkbox no-margin">
    <label
      :for="inputId"
      class="checkbox__label no-margin flex flex-v-center"
    >
      <input
        :id="inputId"
        type="checkbox"
        class="checkbox__input"
        :checked
        :value="option.id"
        @change="onChange"
      >
      <span class="checkbox__input-fake" />
      <span
        class="checkbox__text"
        v-text="option.title"
      />
    </label>
  </li>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { FilterOption } from '@/types/backend'

const props = defineProps<{
  checked: boolean
  groupId: string
  option: FilterOption
}>()

const inputId = computed(() => `${props.groupId}-${props.option.title}`)

const emit = defineEmits<{ click: [checked: boolean] }>()
const onChange = (event: Event) => emit('click', (event.target as HTMLInputElement).checked)
</script>
