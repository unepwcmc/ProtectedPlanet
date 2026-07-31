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
//
// The observer also watches removedNodes and calls `.unmount()` on any island
// whose root leaves the document — e.g. a Tabs panel with a nested
// frontend_mount island (Map, PameTable, ...) being torn down by the outer
// component's own `v-if` when the user switches tabs. Without this, the old
// app instance (its IntersectionObserver/ResizeObserver/MapLibre GL context,
// etc.) would keep running detached from the document, leaking on every
// switch — Vue never calls unmount()/onUnmounted for a node that just gets
// removed by other means.

import { readMountProps } from './readMountProps'
import { pinia } from '@/stores/pinia'

export type IslandLoader = () => Promise<{ default: unknown }>

interface MountedApp {
  unmount: () => void
}

const registry: Record<string, IslandLoader> = {}
// Elements already mounted — guards against double-mounting when the initial
// scan and the observer both see the same node.
const mountedEls = new WeakSet<HTMLElement>()
// The live app instance behind each mounted element, so it can be unmounted
// when the element is removed from the document (see the file header).
const mountedApps = new WeakMap<HTMLElement, MountedApp>()
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
  // Repeated instances of the same registered id (see FrontendHelper#frontend_mount's
  // `key:` option) carry their own props block via `data-props-id`; fall back to `id`
  // for the common one-instance-per-page case.
  const app = createApp(
    mod.default as Parameters<typeof createApp>[0],
    readMountProps(el.dataset.propsId ?? id) ?? {}
  )
  app.use(pinia)
  app.mount(el)
  mountedApps.set(el, app)
  // Vue 3 mounts INTO el rather than replacing it (Vue 2's behaviour), leaving a
  // redundant `<div data-mount>` wrapper around every island's real root. Swap it
  // out for the rendered root so the wrapper doesn't ship to the page. Only safe
  // for single-root components (the only kind used here) — skip otherwise so a
  // future multi-root component degrades to "extra wrapper" instead of losing nodes.
  if (el.childNodes.length === 1 && el.firstElementChild instanceof HTMLElement) {
    const root = el.firstElementChild
    // Carry the identifying markers over so code that looks a mount point up by
    // id/data-mount *after* mounting (tests, devtools, future re-scans) still finds
    // it — only the wrapper's redundant DOM nesting is being removed, not its identity.
    if (el.id) root.id ||= el.id
    // A caller can pass `class:` to frontend_mount to position/style the mount
    // point from outside (e.g. layout-specific classes) — carry those over too,
    // same rationale as id/dataset, or they'd be lost when the wrapper is dropped.
    el.classList.forEach(cls => root.classList.add(cls))
    for (const [key, value] of Object.entries(el.dataset)) {
      if (value !== undefined && !(key in root.dataset)) root.dataset[key] = value
    }
    // `data-mount` is carried over above, so the MutationObserver sees `root` (now
    // bearing that attribute) arrive as a new node when replaceWith fires its
    // childList mutation. Mark it mounted up front so that re-scan is a no-op
    // instead of mounting a second Vue app onto the same node.
    mountedEls.add(root)
    mountedApps.set(root, app)
    mountedApps.delete(el)
    el.replaceWith(root)
  }
}

/** Unmount the app behind `el` (if any) and forget it, so a later re-insertion re-mounts fresh. */
function unmountOne(el: HTMLElement): void {
  const app = mountedApps.get(el)
  if (!app) return
  app.unmount()
  mountedApps.delete(el)
  mountedEls.delete(el)
}

/** Unmount `node` itself (if it's a mounted island) and any mounted islands beneath it. */
function unmountRemoved(node: Node): void {
  if (!(node instanceof HTMLElement)) return
  // The observer's callback runs once per batch of mutations, not synchronously
  // per mutation — mountEl's own wrapper->root swap (el.replaceWith(root)) moves
  // `root` out of `el` and back into the document within the same synchronous
  // block, which shows up here as a "removal" even though `root` is still in the
  // document by the time this callback fires. Only unmount if it's genuinely gone.
  if (node.isConnected) return
  unmountOne(node)
  node.querySelectorAll<HTMLElement>('[data-mount]').forEach(unmountOne)
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
      mutation.removedNodes.forEach(unmountRemoved)
    }
  })
  observer.observe(document.body, { childList: true, subtree: true })
}

/** Stop observing (used by tests). */
export function stopIslands(): void {
  observer?.disconnect()
  observer = null
}
