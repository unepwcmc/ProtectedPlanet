// In-flight download state.
//
// localStorage holds only what identifies a requested download — never its
// status. The server is the authority on whether a file is ready: a stored
// "ready" url can outlive the file it points at, because a release
// finalisation clears the whole downloads keyspace (see
// Download::Requesters::Base#enqueue_generation_once). So every page load asks
// /downloads/poll what the state actually is.
//
// The list itself is the source of truth for what to show, and useStorage keeps
// every open tab's copy in sync via the `storage` event, so a download
// requested in one tab appears in the others.
//
// POST /downloads is only ever sent by the click that requested the download —
// see consumeCreateRequest. A reload, a re-render or another tab can only poll.
//
// Modal chrome is deliberately *not* shared: it goes to sessionStorage, which is
// per-tab and survives a reload, so minimising in one tab can't collapse
// another's.
//
// Cross-tab conflicts are last-write-wins — a `storage` event replaces the local
// array wholesale. Merging per id would need tombstones to stop a delete in one
// tab being resurrected by another's stale copy, which isn't worth it for a list
// that only ever changes on a deliberate click.
import { useEventListener, useStorage } from '@vueuse/core'
import { effectScope, reactive, ref, type EffectScope } from 'vue'

export interface DownloadItemParams {
  id: string
  domain: string
  format: string
  token: string
  // Digest the backend keys a 'search' download off; the poll endpoint needs it
  // in place of `token` for that domain, and only the create response supplies
  // it — so it is the one piece of the server's answer worth keeping.
  backEndToken?: string
  // 'search' domain only — the search state the download was requested with.
  filters?: unknown
  search?: string
  createdAt: number
}

// What a caller supplies; the store owns everything else on the item.
export type NewDownloadItem = Pick<DownloadItemParams, 'domain' | 'format' | 'token'>

export const POLL_INTERVAL_MS = 15_000
// Past this a download is called failed rather than polled forever. Measured
// from createdAt, so it survives reloads.
export const POLL_TIMEOUT_MS = 30 * 60 * 1000

// An item is dropped after 5 days, and the list is capped, so an abandoned
// download can't sit in localStorage being polled for forever.
const MAX_AGE_MS = 5 * 24 * 60 * 60 * 1000
const MAX_ITEMS = 20

const ITEMS_KEY = 'downloadItems'

function newId(): string {
  return crypto.randomUUID()
}

// Reading either storage throws outright in some privacy modes, so every access
// is guarded; useStorage falls back to an in-memory ref when handed undefined.
function safeStorage(pick: () => Storage): Storage | undefined {
  try {
    return pick()
  }
  catch (e) {
    console.error(e)
    return undefined
  }
}

// Reject anything that isn't recognisably an item, and fill in the fields added
// since it was written — a stored value is untrusted input, and a half-shaped
// entry would otherwise reach a v-for and a request payload.
function normaliseItem(raw: unknown): DownloadItemParams | null {
  if (typeof raw !== 'object' || raw === null) return null

  const item = raw as Record<string, unknown>
  if (typeof item.domain !== 'string' || typeof item.format !== 'string' || typeof item.token !== 'string') {
    return null
  }

  return {
    domain: item.domain,
    format: item.format,
    token: item.token,
    backEndToken: typeof item.backEndToken === 'string' ? item.backEndToken : undefined,
    filters: item.filters,
    search: typeof item.search === 'string' ? item.search : undefined,
    id: typeof item.id === 'string' ? item.id : String(item.id ?? newId()),
    createdAt: typeof item.createdAt === 'number' ? item.createdAt : Date.now()
  }
}

function pruneItems(items: DownloadItemParams[], now: number): DownloadItemParams[] {
  return items.filter(item => now - item.createdAt < MAX_AGE_MS).slice(-MAX_ITEMS)
}

// Two requests for the same file in the same state are the same download.
function signature(item: DownloadItemParams): string {
  return [
    item.domain,
    item.format,
    item.token,
    item.search ?? '',
    JSON.stringify(item.filters ?? null)
  ].join('|')
}

// Applied on the initial read and on every cross-tab sync, so expiry and
// validation cover both.
const itemsSerializer = {
  read: (raw: string): DownloadItemParams[] => {
    try {
      const parsed: unknown = JSON.parse(raw)
      if (!Array.isArray(parsed)) return []

      const items = parsed
        .map(normaliseItem)
        .filter((item): item is DownloadItemParams => item !== null)

      // Ids used to be Math.random() integers, so a stored list can hold a
      // collision; two items with one id would break both the v-for key and
      // deletion.
      const byId = new Map(items.map(item => [item.id, item]))

      return pruneItems([...byId.values()], Date.now())
    }
    catch (e) {
      console.error(e)
      return []
    }
  },
  write: (items: DownloadItemParams[]): string => JSON.stringify(items)
}

// The modal chrome and the download status used to be persisted to
// localStorage; the chrome is per-tab now and the status is the server's to
// report, so the old keys are only stale noise.
function forgetLegacyKeys() {
  const storage = safeStorage(() => localStorage)

  storage?.removeItem('isModalActive')
  storage?.removeItem('isModalMinimised')
}

// Shared by every island that touches downloads — see useDownloads below for
// why there is exactly one of these.
function createDownloads() {
  const itemStorage = safeStorage(() => localStorage)

  const downloadItems = useStorage<DownloadItemParams[]>(
    ITEMS_KEY,
    [],
    itemStorage,
    {
      serializer: itemsSerializer,
      // Sync, not the default pre-flush: a click that adds a download and then
      // navigates must not be able to outrun the write.
      flush: 'sync',
      // Cross-tab syncing is handled below instead. useStorage's own listener
      // also fires on a synthetic event it dispatches for each of its *own*
      // writes, and pauses its write-watcher for a tick when it does — so a
      // second change in the same tick as a write (an item added, then patched
      // by the component that add renders) was silently never persisted.
      listenToStorageChanges: false
    }
  )

  // Per-tab, so there is nothing to sync and nothing to listen for.
  const isModalActive = useStorage(
    'isModalActive',
    false,
    safeStorage(() => sessionStorage),
    { flush: 'sync', listenToStorageChanges: false }
  )
  const isModalMinimised = useStorage(
    'isModalMinimised',
    false,
    safeStorage(() => sessionStorage),
    { flush: 'sync', listenToStorageChanges: false }
  )

  // Transient: only ever read at the moment a 'search' download is requested.
  const searchFilters = ref<unknown[]>([])
  const searchTerm = ref('')

  // Ids this page load requested by click, and so may POST /downloads for. It is
  // deliberately in memory only: a reload, a re-render or another tab must not
  // be able to ask the server to generate a file again.
  const createRequests = new Set<string>()

  forgetLegacyKeys()

  // useStorage's read-side prune only updates the in-memory copy, so write the
  // pruned list back. A no-op when nothing was pruned: useStorage compares the
  // serialised value and skips identical writes.
  downloadItems.value = [...downloadItems.value]

  // A real `storage` event never fires in the tab that did the writing, so this
  // only ever sees another tab's changes. (useStorage's synthetic same-document
  // event still arrives; it always matches what is already held, so it stops at
  // the comparison below rather than looping.)
  useEventListener(window, 'storage', (event: StorageEvent) => {
    if (itemStorage === undefined || event.storageArea !== itemStorage) return
    // A null key means the whole storage was cleared.
    if (event.key !== null && event.key !== ITEMS_KEY) return

    const incoming = event.newValue === null ? [] : itemsSerializer.read(event.newValue)
    if (itemsSerializer.write(incoming) === itemsSerializer.write(downloadItems.value)) return

    downloadItems.value = incoming
  })

  function addNewDownloadItem(params: NewDownloadItem): DownloadItemParams {
    const item: DownloadItemParams = {
      ...params,
      // A 'search' download is only reproducible together with the search state
      // it was requested from, and attaching it here means no caller can forget.
      ...(params.domain === 'search' ? { filters: searchFilters.value, search: searchTerm.value } : {}),
      id: newId(),
      createdAt: Date.now()
    }

    isModalMinimised.value = false
    isModalActive.value = true

    // Re-surface an identical request rather than generating the same file
    // twice. (A download that has failed is retried by deleting its row and
    // asking again — this tab cannot tell that it failed, only the server can.)
    const existing = downloadItems.value.find(other => signature(other) === signature(item))
    if (existing) return existing

    createRequests.add(item.id)
    downloadItems.value = pruneItems([...downloadItems.value, item], item.createdAt)

    return item
  }

  // True once, for the item the click that just happened created. Anything else
  // — a reload, another tab, a re-render — gets false and must poll instead.
  function consumeCreateRequest(id: string): boolean {
    return createRequests.delete(id)
  }

  function patchDownloadItem(id: string, patch: Partial<DownloadItemParams>) {
    downloadItems.value = downloadItems.value.map(item => (
      item.id === id ? { ...item, ...patch } : item
    ))
  }

  function deleteDownloadItem(item: Pick<DownloadItemParams, 'id'>) {
    createRequests.delete(item.id)
    downloadItems.value = downloadItems.value.filter(download => download.id !== item.id)
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

  // reactive() so callers read `downloads.downloadItems`, not `.value` — and so
  // Vue templates unwrap it, which they don't do for refs nested in a plain
  // object.
  return reactive({
    downloadItems,
    isModalActive,
    isModalMinimised,
    searchFilters,
    searchTerm,
    addNewDownloadItem,
    consumeCreateRequest,
    patchDownloadItem,
    deleteDownloadItem,
    minimiseDownloadModal,
    toggleDownloadModal,
    updateSearchFilters,
    updateSearchTerm
  })
}

export type Downloads = ReturnType<typeof createDownloads>

let downloads: Downloads | null = null
let scope: EffectScope | null = null

/**
 * The download queue: the list of requested downloads, plus the modal's own
 * per-tab chrome.
 *
 * There is one instance, created on first use and shared by every island —
 * `Download/Index.vue`, `Download/Modal.vue` and `SearchAreas/Page.vue` are
 * separate Vue apps, and the create-request gate and search state are
 * in-memory, so a second instance would silently break them.
 *
 * Its effects (the storage write-watcher, the `storage` listener) live in a
 * detached scope on purpose: created inside whichever island asked first, they
 * would be disposed when that island unmounts, taking every other island's
 * persistence and cross-tab syncing with them.
 */
export function useDownloads(): Downloads {
  if (downloads === null) {
    scope = effectScope(true)
    downloads = scope.run(createDownloads) as Downloads
  }

  return downloads
}

// Tests only: drops the shared instance and stops its effects, so each case
// starts from empty state with no listener left over from the last one.
export function resetDownloads(): void {
  scope?.stop()
  scope = null
  downloads = null
}
