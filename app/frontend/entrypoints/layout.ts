// Global entrypoint — loaded on every page.
//
// Island-mount foundation for the Webpacker->Vite migration. Each `frontend_mount`
// element on the page gets its own Vue 3 app (createApp), mounted here, while the
// legacy Vue 2 tree still runs under Webpacker's #v-app during the overlap.
// `vue` resolves to Vue 3 here (Vite alias -> vue3); Webpacker keeps Vue 2.
//
// To migrate a component (island-by-island):
//   1. Add its Vue 3 SFC under app/frontend/components/.
//   2. Register it below: `'<mount-id>': MyComponent`.
//   3. In the ERB, render `<%= frontend_mount "<mount-id>", props: {...} %>` and
//      remove the old <tag> from Webpacker's #v-app (so exactly one system compiles it).
//
// See:
//   app/helpers/frontend_helper.rb          (server side: emits mount + props)
//   app/frontend/lib/readMountProps.ts       (client side: reads props)
//   upgrade-plan/frontend/14-architecture-and-design.md

import { createApp, type Component } from 'vue'
import { readMountProps } from '../lib/readMountProps'

// Island id -> Vue 3 root component. Empty until the first component is migrated.
const islands: Record<string, Component> = {}

function mountIslands(): void {
  document.querySelectorAll<HTMLElement>('[data-mount]').forEach((el) => {
    const id = el.dataset.mount
    if (!id) return
    const root = islands[id]
    if (!root) return // still handled by Webpacker's #v-app
    createApp(root, readMountProps(id) ?? {}).mount(el)
  })
}

document.addEventListener('DOMContentLoaded', mountIslands)
