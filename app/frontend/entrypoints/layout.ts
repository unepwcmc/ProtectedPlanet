// Global entrypoint — loaded on every page (see layouts/partials/_head.html.erb).
//
// Registers the Vue 3 "islands" available during the Webpacker->Vite migration and
// starts the mounter. The mounter (app/frontend/lib/islands.ts) lazily loads Vue
// only when a `frontend_mount` element is present, and keeps watching the DOM so a
// mount point revealed later (e.g. inside a `v-if` region) still mounts — so we are
// never forced to keep hidden regions alive with `v-show`.
//
// To migrate a component (island-by-island):
//   1. Add its Vue 3 SFC under app/frontend/components/.
//   2. Register a lazy loader below.
//   3. In the ERB, render `<%= frontend_mount "<id>", props: {...} %>` and remove the
//      old <tag> from Webpacker's #v-app (so exactly one system compiles it).
//
// See: app/helpers/frontend_helper.rb, app/frontend/lib/readMountProps.ts,
//      app/frontend/lib/islands.ts, upgrade-plan/frontend/14-architecture-and-design.md

// Tailwind v4 (utilities only, preflight disabled) — loads on every page. See the
// file header for why preflight is off during the SCSS coexistence period.
import '@/styles/tailwind.css'

import { registerIslands, startIslands } from '@/lib/islands'

registerIslands({
  // Global chrome banner — first migrated island. Rendered by
  // app/views/layouts/partials/_banner.html.erb via frontend_mount "Banner".
  Banner: () => import('@/components/Banner.vue'),
  // Tabbed pages (thematic/data). Validated Vue 3 Tabs island using real v-if panels
  // (see Tabs.vue + specs). Not yet wired to a live page — the first real tab-page
  // migration (e.g. wdpca) will register its page island here and use frontend_mount.
  Tabs: () => import('@/components/Tabs.vue')
})

// Mount on DOMContentLoaded, NOT immediately. Webpacker's Vue 2 registers its
// `#v-app` mount on DOMContentLoaded from a classic <script> in <head> (which runs
// before this deferred module), so waiting for the same event means Vue 2 rebuilds
// `#v-app` FIRST. Islands that sit inside `#v-app` then mount into the final node
// once — no mount/re-mount race. (`complete` = the event already fired.)
if (document.readyState === 'complete') {
  startIslands()
}
else {
  document.addEventListener('DOMContentLoaded', startIslands, { once: true })
}
