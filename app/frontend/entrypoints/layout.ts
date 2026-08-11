// Global entrypoint — loaded on every page (see layouts/partials/_head.html.erb).
//
// Registers the Vue 3 "islands" and starts the mounter. The mounter
// (app/frontend/lib/islands.ts) lazily loads Vue only when a `frontend_mount`
// element is present, and keeps watching the DOM so a mount point revealed later
// (e.g. inside a `v-if` region) still mounts — so we are never forced to keep
// hidden regions alive with `v-show`.
//
// To add a new component:
//   1. Add its Vue 3 SFC under app/frontend/components/.
//   2. Register a lazy loader below.
//   3. In the ERB, render `<%= frontend_mount "<id>", props: {...} %>`.
//
// See: app/helpers/frontend_helper.rb, app/frontend/lib/readMountProps.ts,
//      app/frontend/lib/islands.ts, upgrade-plan/frontend/14-architecture-and-design.md

// Tailwind v4 (utilities only, preflight disabled) — loads on every page. See the
// file header for why preflight is off during the SCSS coexistence period.
import '@/styles/tailwind.css'

import { registerIslands, startIslands } from '@/lib/islands'
import useAnalytics from '@/composables/useAnalytics'

// Resumes optional tracking (GA4/Hotjar) for visitors who already accepted cookies
// on a previous visit — the CookieConsent island only fires on the first decision.
useAnalytics().initAnalytics()

registerIslands({
  Banner: () => import('@/components/Banner/Index.vue'),
  CookieConsent: () => import('@/components/CookieConsent.vue'),
  Tabs: () => import('@/components/Tabs.vue'),
  GaLink: () => import('@/components/GaLink.vue'),
  Counter: () => import('@/components/Counter.vue'),
  ListingPageCardNews: () => import('@/components/ListingPageCard/News/Index.vue'),
  ListingPageCardResources: () => import('@/components/ListingPageCard/Resources/Index.vue'),
  Tooltip: () => import('@/components/Tooltip/Index.vue'),
  TooltipSecond: () => import('@/components/Tooltip/Second.vue'),
  NavBar: () => import('@/components/NavBar/Index.vue'),
  SearchSiteTopbar: () => import('@/components/Search/SiteTopbar.vue'),
  Download: () => import('@/components/Download/Index.vue'),
  DownloadModal: () => import('@/components/Download/Modal.vue'),
  Listing: () => import('@/components/Listing/Index.vue'),
  Map: () => import('@/components/Map/Index.vue'),
  SearchAreasPage: () => import('@/components/SearchAreas/Page.vue'),
  SearchAreas: () => import('@/components/SearchAreas/Index.vue'),
  RegionCountryPages: () => import('@/components/RegionCountryPages/Index.vue'),
  StatsTooltipInfo: () => import('@/components/Stats/TooltipInfo.vue'),
  ChartTotalCoverageChart: () => import('@/components/Chart/TotalCoverageChart.vue'),
  AmChartMultiline: () => import('@/components/AmChart/Multiline.vue'),
  AttributesParcelsDropdown: () => import('@/components/Dropdown/ParcelsDropdown.vue'),
  AttributesProtectedArea: () => import('@/components/Attributes/ProtectedArea/Index.vue'),
  AttributesPameList: () => import('@/components/Attributes/Pame/List.vue'),
  AttributesAffiliations: () => import('@/components/Attributes/Affiliations/Index.vue'),
  AttributesProtectedAreaSources: () => import('@/components/Attributes/ProtectedArea/Source/List.vue'),
  PameTable: () => import('@/components/Pame/Table/Index.vue'),
  CarouselThemes: () => import('@/components/Carousel/Themes/Index.vue'),
  SearchSite: () => import('@/components/Search/Index.vue')
})

if (document.readyState === 'complete') {
  startIslands()
}
else {
  document.addEventListener('DOMContentLoaded', startIslands, { once: true })
}
