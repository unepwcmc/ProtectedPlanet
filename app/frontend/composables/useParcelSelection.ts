import { onMounted, onUnmounted, ref } from 'vue'
import { PARCEL_ID_PARAM, PARCEL_SELECTED_EVENT } from '@/constants/attributes'

function readParcelIdFromUrl(): string | null {
  return new URLSearchParams(window.location.search).get(PARCEL_ID_PARAM)
}

export function useParcelSelection() {
  const selectedParcelId = ref(readParcelIdFromUrl())

  function refresh() {
    selectedParcelId.value = readParcelIdFromUrl()
  }

  function selectParcel(parcelId: string) {
    const urlParams = new URLSearchParams(window.location.search)
    urlParams.set(PARCEL_ID_PARAM, parcelId)
    window.history.replaceState({}, '', `${window.location.pathname}?${urlParams.toString()}`)
    refresh()
    window.dispatchEvent(new Event(PARCEL_SELECTED_EVENT))
  }

  onMounted(() => window.addEventListener(PARCEL_SELECTED_EVENT, refresh))
  onUnmounted(() => window.removeEventListener(PARCEL_SELECTED_EVENT, refresh))

  return { selectedParcelId, selectParcel }
}
