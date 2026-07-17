// Global entrypoint — loaded on every page (nav, topbar search, download modal).
//
// This is the island-mount foundation. During the migration overlap (Rails 5.2,
// Vite 2.9, Node 12) Vue components are still served by Webpacker's #v-app, so no
// components are mounted here yet. Phase 4 (Vue 3) fills the `islands` registry
// below and each `frontend_mount` on the page gets createApp()'d into its element.
//
// See:
//   app/helpers/frontend_helper.rb          (server side: emits mount + props)
//   app/frontend/lib/readMountProps.ts       (client side: reads props)
//   upgrade-plan/frontend/14-architecture-and-design.md

import { readMountProps, mountEl } from '../lib/readMountProps'

// Island id -> mount function. Populated in phase 4 with Vue 3 createApp() calls,
// e.g. { 'nav-burger': (el, props) => createApp(NavBurger, props).mount(el) }
type MountFn = (el: HTMLElement, props: Record<string, unknown> | null) => void

const islands: Record<string, MountFn> = {}

function mountIslands(): void {
  document.querySelectorAll<HTMLElement>('[data-mount]').forEach((el) => {
    const id = el.dataset.mount
    if (!id) return
    const mount = islands[id]
    if (!mount) return // handled by Webpacker's #v-app until phase 4
    mount(el, readMountProps(id))
  })
  // reference kept so the helper stays tree-shake-safe until islands are added
  void mountEl
}

document.addEventListener('DOMContentLoaded', mountIslands)
