<template>
  <div
    v-show="options.length > 0"
    class="flex flex-wrap flex-column"
  >
    <p
      v-for="option in options"
      :key="radioId(option)"
      class="radio no-margin"
    >
      <label
        :for="radioId(option)"
        class="radio__label no-margin flex flex-v-center"
      >
        <input
          :id="radioId(option)"
          v-model="input"
          required
          type="radio"
          class="radio__input"
          :value="option.id"
          :name
          @click="changeInput(option.id)"
        >
        <span class="radio__input-fake" />
        <span v-text="option.title" />
      </label>
    </p>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import type { SearchFilterOption } from '@/types/backend'

const props = withDefaults(defineProps<{
  id: string
  name: string
  options?: SearchFilterOption[]
  preSelected?: string
  resetKey?: number
}>(), {
  options: () => [],
  preSelected: '',
  resetKey: 0
})

const emit = defineEmits<{ 'update:options': [option: string] }>()

const input = ref(props.preSelected)

function changeInput(id: string) {
  input.value = id
  emit('update:options', input.value)
}

function reset() {
  input.value = ''
}

function radioId(option: SearchFilterOption) {
  return `${props.name}-${option.id}}`
}

watch(() => props.resetKey, () => {
  reset()
  changeInput('')
})

changeInput(props.preSelected)
</script>
