import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { PameEvaluationItem, PameFilterSelection } from '@/types/backend'

export const usePameStore = defineStore('pame', () => {
  const requestedPage = ref(1)
  const selectedFilterOptions = ref<PameFilterSelection[]>([])
  const modalContent = ref<PameEvaluationItem | null>(null)
  const isModalOpen = ref(false)
  // One shared in-flight flag for every PAME network call (list fetch, CSV
  // download) so the table, pagination, filters, and download button all disable
  // together — otherwise a page-change click during a filter apply (or vice versa)
  // fires overlapping requests.
  const isFetching = ref(false)

  function setFilterOptions(options: PameFilterSelection[]) {
    selectedFilterOptions.value = options
  }

  function updateFilterOptions(filterName: string, options: Array<string | number>) {
    const filter = selectedFilterOptions.value.find(f => f.name === filterName)
    if (filter) filter.options = options
  }

  function updateRequestedPage(page: number) {
    requestedPage.value = page
  }

  function openModal(item: PameEvaluationItem) {
    modalContent.value = item
    isModalOpen.value = true
  }

  function closeModal() {
    isModalOpen.value = false
  }

  function setFetching(value: boolean) {
    isFetching.value = value
  }

  return {
    requestedPage,
    selectedFilterOptions,
    modalContent,
    isModalOpen,
    isFetching,
    setFilterOptions,
    updateFilterOptions,
    updateRequestedPage,
    openModal,
    closeModal,
    setFetching
  }
})
