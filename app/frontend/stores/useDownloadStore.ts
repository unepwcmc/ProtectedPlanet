// Vue3/Pinia port of the legacy Vuex `download` module
// (app/javascript/store/_store-download.js) — same state shape and behaviour,
// including the localStorage persistence contract, so existing in-flight
// downloads survive the Webpacker->Vite cutover for a given browser session.
import { defineStore } from 'pinia'
import { ref } from 'vue'

export interface DownloadItemParams {
  id: number
  domain: string
  format: string
  token: string
  backEndToken?: string
  filters?: unknown
  search?: string
}

export const useDownloadStore = defineStore('download', () => {
  const downloadItems = ref<DownloadItemParams[]>([])
  const isModalActive = ref(false)
  const isModalMinimised = ref(false)
  const searchFilters = ref<unknown[]>([])
  const searchTerm = ref('')

  function addNewDownloadItem(item: DownloadItemParams) {
    downloadItems.value = [...downloadItems.value, item]
    isModalMinimised.value = false
    isModalActive.value = true
  }

  function deleteDownloadItem(item: DownloadItemParams) {
    downloadItems.value = downloadItems.value.filter(download => download.id !== item.id)
  }

  // Mirrors the legacy per-key try/catch: a corrupt value for one key resets
  // only that key, it doesn't abort initialising the others.
  function initialiseStore() {
    if (localStorage.getItem('downloadItems') !== null) {
      try {
        downloadItems.value = JSON.parse(localStorage.getItem('downloadItems') as string)
      }
      catch (e) {
        console.error(e)
        downloadItems.value = []
      }
    }

    if (localStorage.getItem('isModalActive') !== null) {
      try {
        isModalActive.value = !!JSON.parse(localStorage.getItem('isModalActive') as string)
      }
      catch (e) {
        console.error(e)
        isModalActive.value = false
      }
    }

    if (localStorage.getItem('isModalMinimised') !== null) {
      try {
        isModalMinimised.value = !!JSON.parse(localStorage.getItem('isModalMinimised') as string)
      }
      catch (e) {
        console.error(e)
        isModalMinimised.value = true
      }
    }
  }

  function updateLocalStorage() {
    localStorage.setItem('downloadItems', JSON.stringify(downloadItems.value))
    localStorage.setItem('isModalActive', isModalActive.value.toString())
    localStorage.setItem('isModalMinimised', isModalMinimised.value.toString())
  }

  function minimiseDownloadModal(minimised: boolean) {
    isModalMinimised.value = minimised
  }

  function toggleDownloadModal(active: boolean) {
    isModalActive.value = active
  }

  function updateSearchFilters(filters: unknown[]) {
    searchFilters.value = filters
  }

  function updateSearchTerm(term: string) {
    searchTerm.value = term
  }

  return {
    downloadItems,
    isModalActive,
    isModalMinimised,
    searchFilters,
    searchTerm,
    addNewDownloadItem,
    deleteDownloadItem,
    initialiseStore,
    updateLocalStorage,
    minimiseDownloadModal,
    toggleDownloadModal,
    updateSearchFilters,
    updateSearchTerm
  }
})
