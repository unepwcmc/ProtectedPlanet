<template>
  <div
    ref="root"
    class="ct-search-areas-autocomplete"
  >
    <div class="ct-search-areas-autocomplete__search-bar">
      <IconSearch class="ct-search-areas-autocomplete__icon" />
      <input
        v-model="searchTerm"
        class="ct-search-areas-autocomplete__input"
        type="text"
        :placeholder="config.placeholder"
        @keyup="onKeyup"
        @keyup.enter="submit"
      >
      <button
        v-show="showResetIcon"
        class="ct-search-areas-autocomplete__delete"
        @click="resetSearchTerm"
      >
        <IconClose class="ct-search-areas-autocomplete__delete-icon" />
      </button>
    </div>
    <div
      v-show="autocomplete.length > 0"
      class="ct-search-areas-autocomplete__dropdown"
    >
      <ul
        class="ct-search-areas-autocomplete__list"
        role="listbox"
      >
        <li
          v-for="option in autocomplete"
          :key="option.id"
          class="ct-search-areas-autocomplete__item"
          role="option"
        >
          <a
            class="ct-search-areas-autocomplete__link"
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
import IconClose from '@/components/Icon/Close.vue'
import IconSearch from '@/components/Icon/Search.vue'
import usePopupCloseListeners from '@/composables/usePopupCloseListeners'
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

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-search-areas-autocomplete {
  @apply
  relative
  w-full;
}

.ct-search-areas-autocomplete__search-bar {
  @apply relative
  z-2
  tw-shared-base-flex-gap-3
  justify-between
  items-center
  rounded-full
  border-2
  border-theme-grey
  bg-white
  py-1
  px-4;
}

.ct-search-areas-autocomplete__icon {
  @apply
  size-5.25
  text-black;
}

.ct-search-areas-autocomplete__input {
  @apply
  tw-shared-font-hind-siliguri__light-lg-grey-black
  h-8
  md:h-10
  grow;
}

.ct-search-areas-autocomplete__input:focus {
  @apply
  outline-none;
}

.ct-search-areas-autocomplete__delete {
  @apply cursor-pointer;
}

.ct-search-areas-autocomplete__delete-icon {
  @apply
  size-4
  text-black;
}

.ct-search-areas-autocomplete__dropdown {
  @apply
  absolute
  top-1/2
  right-0
  z-1
  w-full
  rounded-b-[2.3rem]
  border-x-2
  border-x-theme-grey
  border-b-2
  border-b-theme-grey
  bg-white
  pt-9
  pb-7;
}

.ct-search-areas-autocomplete__list {
  @apply
  max-h-72
  overflow-y-scroll
  pt-6
  tw-shared-base-flex-col;
}

.ct-search-areas-autocomplete__item {
  @apply
  flex
  cursor-pointer;
}

.ct-search-areas-autocomplete__item:hover {
  @apply bg-theme-grey-light;
}

.ct-search-areas-autocomplete__link {
  @apply
  w-full
  px-10
  py-2.5
  tw-shared-font-hind-siliguri__light-lg-grey-black
  no-underline;
}
</style>
