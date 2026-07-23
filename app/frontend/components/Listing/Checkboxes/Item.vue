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
        :checked="checked"
        :value="option.id"
        @change="emit('change', ($event.target as HTMLInputElement).checked)"
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
import type { ListingFilterOption } from '@/types/backend'

const props = defineProps<{
  checked: boolean
  groupId: string
  option: ListingFilterOption
}>()

const emit = defineEmits<{ change: [checked: boolean] }>()

const inputId = computed(() => `${props.groupId}-${props.option.title}`)
</script>
