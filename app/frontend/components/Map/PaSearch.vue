<template>
  <div
    ref="root"
    class="v-map-pa-search"
  >
    <div class="autocomplete__container">
      <div class="autocomplete">
        <button
          class="autocomplete__magnifying-glass"
          type="button"
          @click="onMagnifyingGlassClick"
        />
        <input
          ref="inputEl"
          v-model="search"
          class="autocomplete__input"
          type="text"
          :placeholder="autocompletePlaceholder"
          @input="onInput"
          @keyup.enter.prevent.stop="onInputEnter"
          @keyup.esc.prevent.stop="reset"
        >
        <button
          v-if="hasSearchString"
          class="autocomplete__delete"
          type="button"
          @click="reset"
        />
      </div>
      <div
        v-show="showResultsPane"
        class="autocomplete__results-container"
      >
        <div
          v-if="hasTooShortError"
          class="autocomplete__error-message"
          v-text="autocompleteErrorMessages.invalid_search_string"
        />
        <div
          v-if="hasNoResultsError"
          class="autocomplete__error-message"
          v-text="autocompleteErrorMessages.no_results"
        />
        <div class="autocomplete__results">
          <div
            v-for="(result, index) in results"
            :key="index"
            ref="resultEls"
            class="autocomplete__result"
            tabindex="0"
            @click="submit(result)"
            @keyup.enter.stop.prevent="submit(result)"
            @mouseover="focusResult(index)"
            v-text="result.title"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
// Vue 3 port of the legacy VMapPASearch.vue + Autocomplete.vue pair
// (app/javascript/components/map/VMapPASearch.vue) — merged into one component
// since only the map PA-search box uses this markup here (site/area search get
// their own autocomplete in a later wave). Reuses the legacy unprefixed BEM
// classes (`.v-map-pa-search`, `.autocomplete__*`) as-is, same exception as the
// Wave 3 nav/search chrome — this is high-traffic global map UI, not a fresh
// component, so it keeps its existing styling rather than a `ct-` rewrite.
import { ref, computed } from 'vue'
import { onClickOutside, useDebounceFn } from '@vueuse/core'
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
