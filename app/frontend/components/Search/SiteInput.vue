<template>
  <div class="search search--main">
    <button
      v-if="popout"
      class="search__trigger"
      @click="toggleInput"
    />

    <div
      class="search__pane"
      :class="{ active: isActive, popout: popout }"
    >
      <input
        ref="inputEl"
        v-model="searchTerm"
        type="text"
        class="search__input"
        :placeholder="placeholder"
        @keyup.enter="submit"
      >

      <i class="search__icon" />

      <button
        v-show="showClose"
        class="search__close"
        @click="closeInput"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'

const props = defineProps<{
  placeholder: string
  popout?: boolean
  prePopulatedSearchTerm?: string
}>()

const emit = defineEmits<{ 'submit:search': [searchTerm: string] }>()

const isActive = ref(!props.popout)
const searchTerm = ref(props.prePopulatedSearchTerm ?? '')
const inputEl = ref<HTMLInputElement | null>(null)

const showClose = computed(() => props.popout || searchTerm.value.length !== 0)

function closeInput() {
  if (props.popout) isActive.value = false
  searchTerm.value = ''
}

function submit() {
  emit('submit:search', searchTerm.value)
}

function toggleInput() {
  isActive.value = !isActive.value
  // Matches the legacy component's own setTimeout(0): waits a macrotask past
  // Vue's render flush so the popout pane's CSS transition has started before
  // focusing, not just nextTick's "DOM updated" point.
  setTimeout(() => inputEl.value?.focus(), 0)
}
</script>
