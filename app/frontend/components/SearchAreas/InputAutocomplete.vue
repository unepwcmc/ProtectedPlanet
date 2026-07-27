<template>
  <div
    ref="root"
    class="search--autocomplete"
  >
    <div class="search__search">
      <i class="search__search-icon" />
      <input
        v-model="searchTerm"
        class="search__search-input"
        type="text"
        :placeholder="config.placeholder"
        @keyup="onKeyup"
        @keyup.enter="submit"
      >
    </div>
    <button
      v-show="showResetIcon"
      class="search__search-icon--delete"
      @click="resetSearchTerm"
    />
    <div
      v-show="autocomplete.length > 0"
      class="search__dropdown"
    >
      <ul
        class="search__ul"
        role="listbox"
      >
        <li
          v-for="option in autocomplete"
          :key="option.id"
          class="search__li"
          role="option"
        >
          <a
            class="search__a"
            :href="option.url"
            v-html="option.title"
          />
        </li>
      </ul>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useDebounceFn } from '@vueuse/core'
import { usePopupCloseListeners } from '@/composables/usePopupCloseListeners'
import { postJson } from '@/lib/http'
import type { SearchAreasConfig, AutocompleteResult } from '@/types/backend'

const props = defineProps<{
  config: SearchAreasConfig
  endpoint: string
  prePopulatedSearchTerm?: string
}>()

const emit = defineEmits<{ 'submit:search': [searchTerm: string] }>()

const root = ref<HTMLElement | null>(null)
const searchTerm = ref(props.prePopulatedSearchTerm ?? '')
const autocomplete = ref<AutocompleteResult[]>([])

const showResetIcon = computed(() => searchTerm.value.length !== 0)
const isDropdownOpen = computed(() => autocomplete.value.length > 0)

async function updateAutocomplete() {
  const results = await postJson<AutocompleteResult[]>(props.endpoint, {
    search_term: searchTerm.value,
    type: props.config.id
  })

  autocomplete.value = results
}

const updateAutocompleteDebounced = useDebounceFn(updateAutocomplete, 500)

function onKeyup(e: KeyboardEvent) {
  if (e.key === 'Enter') {
    resetAutocomplete()
    return
  }

  updateAutocompleteDebounced()
}

function resetSearchTerm() {
  searchTerm.value = ''
  resetAutocomplete()
}

function resetAutocomplete() {
  autocomplete.value = []
}

function submit() {
  emit('submit:search', searchTerm.value)
}

usePopupCloseListeners(root, { isActive: isDropdownOpen, onClose: resetAutocomplete })

watch(() => props.prePopulatedSearchTerm, () => {
  searchTerm.value = props.prePopulatedSearchTerm ?? ''
})
</script>
