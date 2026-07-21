// Island mounter for the Webpacker->Vite migration.
//
// Each `frontend_mount` element (see app/helpers/frontend_helper.rb) is a small
// Vue 3 app mounted into its own DOM node. This module finds those nodes and
// mounts the registered component, lazily loading Vue only when an island is
// actually present.
//
// Why a MutationObserver (not just a one-shot DOMContentLoaded scan):
// a mount point can enter the DOM AFTER first paint — e.g. it lives inside a
// region another component reveals with `v-if`, or it arrives via a later
// navigation. A one-shot scan misses those, which forces teams to keep every
// such region in the DOM with `v-show`. Observing added nodes means a mount
// point that appears later still mounts, so `v-if` (true unmount/remount) is
// safe to use freely.

import { readMountProps } from './readMountProps'

export type IslandLoader = () => Promise<{ default: unknown }>

const registry: Record<string, IslandLoader> = {}
// Elements already mounted — guards against double-mounting when the initial
// scan and the observer both see the same node.
const mountedEls = new WeakSet<HTMLElement>()
let observer: MutationObserver | null = null
let createAppPromise: Promise<(typeof import('vue'))['createApp']> | null = null

/** Register island id -> lazy component loader. */
export function registerIslands(map: Record<string, IslandLoader>): void {
  Object.assign(registry, map)
}

function loadCreateApp() {
  if (!createAppPromise) {
    createAppPromise = import('vue').then(m => m.createApp)
  }
  return createAppPromise
}

/** Mount a single element if it is a registered, not-yet-mounted island. */
export async function mountEl(el: HTMLElement): Promise<void> {
  const id = el.dataset.mount
  if (!id || !registry[id] || mountedEls.has(el)) return
  // Mark before awaiting so a concurrent observer callback can't double-mount.
  mountedEls.add(el)
  const [createApp, mod] = await Promise.all([loadCreateApp(), registry[id]()])
  createApp(
    mod.default as Parameters<typeof createApp>[0],
    readMountProps(id) ?? {}
  ).mount(el)
}

/** Mount `root` itself (if it's a mount point) and any mount points beneath it. */
export function mountAll(root: ParentNode = document): void {
  if (root instanceof HTMLElement && root.dataset.mount) void mountEl(root)
  root.querySelectorAll<HTMLElement>('[data-mount]').forEach(el => void mountEl(el))
}

/** Scan the current DOM, then watch for mount points added later. Idempotent. */
export function startIslands(): void {
  mountAll(document)
  if (observer || typeof MutationObserver === 'undefined' || !document.body) return
  observer = new MutationObserver((mutations) => {
    for (const mutation of mutations) {
      mutation.addedNodes.forEach((node) => {
        if (node instanceof HTMLElement) mountAll(node)
      })
    }
  })
  observer.observe(document.body, { childList: true, subtree: true })
}

/** Stop observing (used by tests). */
export function stopIslands(): void {
  observer?.disconnect()
  observer = null
}
