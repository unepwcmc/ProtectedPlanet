<template>
  <div
    ref="root"
    class="ct-map-pa-search"
  >
    <div class="ct-map-pa-search__bar">
      <button
        class="ct-map-pa-search__magnifying-glass"
        type="button"
        @click="onMagnifyingGlassClick"
      >
        <IconSearch class="ct-map-pa-search__magnifying-glass-icon" />
      </button>
      <input
        ref="inputEl"
        v-model="search"
        name="pa_search"
        class="ct-map-pa-search__input"
        type="text"
        :placeholder="autocompletePlaceholder"
        @input="onInput"
        @keyup.enter.prevent.stop="onInputEnter"
        @keyup.esc.prevent.stop="reset"
      >
      <button
        v-if="hasSearchString"
        class="ct-map-pa-search__delete"
        type="button"
        @click="reset"
      >
        <IconClose class="ct-map-pa-search__delete-icon" />
      </button>
    </div>
    <ul
      v-if="showResultsPane"
      class="ct-map-pa-search__results"
    >
      <li
        v-if="hasTooShortError"
        class="ct-map-pa-search__result
        ct-map-pa-search__result--no-pointer"
        v-text="autocompleteErrorMessages.invalid_search_string"
      />
      <li
        v-if="hasNoResultsError"
        class="ct-map-pa-search__result
        ct-map-pa-search__result--no-pointer"
        v-text="autocompleteErrorMessages.no_results"
      />
      <li
        v-for="(result, index) in results"
        :key="index"
        ref="resultEls"
        class="ct-map-pa-search__result"
        tabindex="0"
        @click="submit(result)"
        @keyup.enter.stop.prevent="submit(result)"
        @mouseover="focusResult(index)"
        v-text="result.title"
      />
    </ul>
  </div>
</template>

<script setup lang="ts">
// Vue 3 port of the legacy VMapPASearch.vue + Autocomplete.vue pair
// (app/javascript/components/map/VMapPASearch.vue) — merged into one component
// since only the map PA-search box uses this markup here (site/area search
// has its own equivalent, SearchAreas/InputAutocomplete.vue, whose structure
// this mirrors).
import { ref, computed } from 'vue'
import { onClickOutside, useDebounceFn } from '@vueuse/core'
import IconClose from '@/components/Icon/Close.vue'
import IconSearch from '@/components/Icon/Search.vue'
import { postJson } from '@/lib/http'
import type { MapPaSearchProps, AutocompleteResult } from '@/types/backend'
import type { ZoomToOptions } from '@/composables/useMapBoundingBox'

type MapPaSearch = MapPaSearchProps
const props = defineProps<MapPaSearch>()
const emit = defineEmits<{ zoomTo: [options: ZoomToOptions] }>()

const root = ref<HTMLElement | null>(null)
const inputEl = ref<HTMLInputElement | null>(null)
const resultEls = ref<HTMLElement[]>([])

const search = ref('')
const results = ref<AutocompleteResult[]>([])
const shouldShowResults = ref(false)
const isBusy = ref(false)
const hasNoResultsError = ref(false)

const hasSearchString = computed(() => search.value.length > 0)
const isValidSearchString = computed(() => search.value.length > 2)
const hasResults = computed(() => results.value.length > 0)
const hasTooShortError = computed(() => hasSearchString.value && !isValidSearchString.value)
const showResultsPane = computed(() => hasSearchString.value && shouldShowResults.value)

onClickOutside(root, () => {
  shouldShowResults.value = false
})

function reset() {
  search.value = ''
  results.value = []
  hasNoResultsError.value = false
}

function focusResult(index: number) {
  resultEls.value[index]?.focus()
}

const runAutocomplete = useDebounceFn(async () => {
  if (!isValidSearchString.value) return

  isBusy.value = true
  hasNoResultsError.value = false
  const searchTerm = search.value

  try {
    const response = await postJson<AutocompleteResult[]>('/search/autocomplete', {
      search_term: searchTerm,
      type: props.type,
      index: 'areas'
    })

    // The term may have changed while the request was in flight — a stale
    // response should not overwrite a newer (or cleared) search.
    if (search.value !== searchTerm) return

    results.value = response
    hasNoResultsError.value = response.length === 0
  }
  finally {
    isBusy.value = false
  }
}, 500)

function onInput() {
  shouldShowResults.value = true

  if (hasSearchString.value) {
    runAutocomplete()
  }
  else {
    results.value = []
    hasNoResultsError.value = false
  }
}

function onInputEnter() {
  if (!hasSearchString.value) return

  if (hasResults.value) {
    resultEls.value[0]?.focus()
  }
  else {
    hasNoResultsError.value = true
  }
}

function onMagnifyingGlassClick() {
  if (hasSearchString.value) {
    if (hasResults.value) focusResult(0)
    else runAutocomplete()
  }
  else {
    inputEl.value?.focus()
  }
}

function submit(result: AutocompleteResult) {
  search.value = result.title
  results.value = []

  emit('zoomTo', {
    ...result,
    name: result.title,
    addPopup: result.is_pa
  })
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-map-pa-search {
  @apply
  relative;
}

.ct-map-pa-search__bar {
  @apply
  relative
  z-1
  tw-shared-base-flex-gap-2
  justify-between
  items-center
  px-4
  py-2
  bg-theme-grey-dark
  border
  border-white
  rounded-full;
}

.ct-map-pa-search__magnifying-glass-icon {
  @apply
  size-5.25
  text-white;
}

.ct-map-pa-search__input {
  @apply
  grow
  tw-shared-font-hind-siliguri__light-lg-grey-black
  placeholder:text-theme-grey-light
  w-full
  flex
  flex-1;
}

.ct-map-pa-search__input:focus {
  @apply
  outline-none
  border-white;
}

.ct-map-pa-search__delete-icon {
  @apply
  tw-shared-icon-button-reset
  size-3.5
  text-white;
}

.ct-map-pa-search__results {
  @apply
  bg-theme-grey-dark
  border
  border-white
  rounded-b-3xl
  pt-6.25
  pb-6.25
  w-full
  absolute
  top-[60%]
  left-0
  overflow-y-scroll
  h-70
  tw-shared-base-flex-col-gap-1;
}

.ct-map-pa-search__result {
  @apply
  p-3
  tw-shared-font-hind-siliguri__light-base-grey-light
  cursor-default;
}

.ct-map-pa-search__result--no-pointer {
  @apply
  cursor-text;
}

.ct-map-pa-search__result:focus,
.ct-map-pa-search__result:hover {
  @apply
  bg-theme-grey-xlight
  text-theme-grey-black;
}
</style>
