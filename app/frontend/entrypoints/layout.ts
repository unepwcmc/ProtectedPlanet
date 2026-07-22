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
  Banner: () => import('@/components/Banner/Index.vue'),
  Tabs: () => import('@/components/Tabs.vue'),
  GaLink: () => import('@/components/GaLink.vue'),
  Counter: () => import('@/components/Counter.vue'),
  ListingPageCardNews: () => import('@/components/ListingPageCard/News/Index.vue'),
  ListingPageCardResources: () => import('@/components/ListingPageCard/Resources/Index.vue'),
  Tooltip: () => import('@/components/Tooltip/Index.vue'),
  TooltipSecond: () => import('@/components/Tooltip/Second.vue'),
  NavBar: () => import('@/components/NavBar/Index.vue'),
  SearchSiteTopbar: () => import('@/components/Search/SiteTopbar.vue')
})

if (document.readyState === 'complete') {
  startIslands()
}
else {
  document.addEventListener('DOMContentLoaded', startIslands, { once: true })
}
