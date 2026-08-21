// In-flight download state, persisted to localStorage so a download survives a
// page load for the rest of the browser session.
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

  // Per-key: a corrupt value resets only that key, without aborting the rest.
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
