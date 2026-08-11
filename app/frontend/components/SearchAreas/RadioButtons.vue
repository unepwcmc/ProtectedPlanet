<template>
  <div
    v-show="options.length > 0"
    class="ct-search-areas-radio-buttons"
  >
    <p
      v-for="option in options"
      :key="radioId(option)"
      class="ct-search-areas-radio-buttons__option"
    >
      <label
        :for="radioId(option)"
        class="ct-search-areas-radio-buttons__label"
      >
        <input
          :id="radioId(option)"
          v-model="input"
          required
          type="radio"
          class="ct-search-areas-radio-buttons__input"
          :value="option.id"
          :name
          @click="changeInput(option.id)"
        >
        <span class="ct-search-areas-radio-buttons__input-fake" />
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

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-search-areas-radio-buttons {
  @apply flex flex-col flex-wrap;
}

.ct-search-areas-radio-buttons__option {
  @apply m-0;
}

.ct-search-areas-radio-buttons__label {
  @apply
  relative
  flex
  items-center
  tw-shared-font-family-hind-siliguri__leading-1-3-grey-black
  text-sm;
}

.ct-search-areas-radio-buttons__input {
  @apply sr-only;
}

.ct-search-areas-radio-buttons__input-fake {
  @apply
  inline-block
  relative
  shrink-0
  size-5
  mt-1
  mr-2
  mb-1
  ml-1
  rounded-full
  border
  border-solid
  border-theme-grey;
}

.ct-search-areas-radio-buttons__input:checked + .ct-search-areas-radio-buttons__input-fake::before {
  @apply
  content-['']
  block
  absolute
  top-1/2
  left-1/2
  size-3.5
  -translate-x-1/2
  -translate-y-1/2
  rounded-full
  bg-theme-primary;
}

.ct-search-areas-radio-buttons__input:focus + .ct-search-areas-radio-buttons__input-fake {
  @apply outline-none;
}
</style>
