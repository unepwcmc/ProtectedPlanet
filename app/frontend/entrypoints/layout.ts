// Global entrypoint — loaded on every page.
//
// Island-mount foundation for the Webpacker->Vite migration. Each `frontend_mount`
// element on the page gets its own Vue 3 app, mounted here, while the legacy Vue 2
// tree still runs under Webpacker's #v-app during the overlap. `vue` resolves to
// Vue 3 here (Vite alias -> vue3); Webpacker keeps Vue 2.
//
// Vue + each component are loaded LAZILY (dynamic import) so pages with no island
// don't ship the Vue 3 runtime. While `islands` is empty this file stays tiny.
//
// To migrate a component (island-by-island):
//   1. Add its Vue 3 SFC under app/frontend/components/.
//   2. Register a loader below: `'<mount-id>': () => import('../components/My.vue')`.
//   3. In the ERB, render `<%= frontend_mount "<mount-id>", props: {...} %>` and
//      remove the old <tag> from Webpacker's #v-app (so exactly one system compiles it).
//
// See:
//   app/helpers/frontend_helper.rb          (server side: emits mount + props)
//   app/frontend/lib/readMountProps.ts       (client side: reads props)
//   upgrade-plan/frontend/14-architecture-and-design.md

import { readMountProps } from '../lib/readMountProps'

// Island id -> lazy loader for its Vue 3 root component. Empty until the first
// component is migrated. Each loader is only invoked when its mount is on the page.
const islands: Record<string, () => Promise<{ default: unknown }>> = {}

async function mountIslands(): Promise<void> {
  const els = [...document.querySelectorAll<HTMLElement>('[data-mount]')]
    .filter((el) => el.dataset.mount && islands[el.dataset.mount])
  if (!els.length) return // no islands on this page — Vue 3 never loaded

  const { createApp } = await import('vue')
  for (const el of els) {
    const id = el.dataset.mount as string
    const { default: root } = await islands[id]()
    createApp(root as Parameters<typeof createApp>[0], readMountProps(id) ?? {}).mount(el)
  }
}

document.addEventListener('DOMContentLoaded', () => {
  void mountIslands()
})
