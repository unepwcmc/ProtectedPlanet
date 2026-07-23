// Temporary bridge so legacy Vue2/Webpacker code not yet migrated to Vue3 can
// still share the `download` Pinia store with the migrated islands:
// - SearchAreas.vue (Wave 7) feeds its active filters/search term here.
// - Download.vue (still live on search_areas/index.html.erb — its
//   :download-disabled prop is bound to SearchAreas.vue's own reactive state,
//   so it can't move to a Vue3 island until Wave 7) creates items here so the
//   migrated global DownloadModal island sees them in the same list, and reads
//   the search filters/term back for its "search" domain option.
// Webpacker and Vite share no module graph (see vue2-vue3-coexistence-solution
// memory), so `window` is the only bridge available until SearchAreas.vue and
// Download.vue themselves migrate and can just call useDownloadStore()
// directly — remove this file then.
import { useDownloadStore, type DownloadItemParams } from './useDownloadStore'
import { pinia } from './pinia'

declare global {
  interface Window {
    __downloadStoreBridge?: {
      updateSearchFilters: (filters: unknown[]) => void
      updateSearchTerm: (term: string) => void
      addNewDownloadItem: (item: DownloadItemParams) => void
      getSearchFilters: () => unknown[]
      getSearchTerm: () => string
    }
  }
}

export function installDownloadStoreBridge(): void {
  const store = useDownloadStore(pinia)
  window.__downloadStoreBridge = {
    updateSearchFilters: filters => store.updateSearchFilters(filters),
    updateSearchTerm: term => store.updateSearchTerm(term),
    addNewDownloadItem: item => store.addNewDownloadItem(item),
    getSearchFilters: () => store.searchFilters,
    getSearchTerm: () => store.searchTerm
  }
}
