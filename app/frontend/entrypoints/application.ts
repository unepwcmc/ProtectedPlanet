// Anything frontend code other than Vue can be in here, but you shouldn't need
// to add anything as all frontend should be without Vue (erb view + tailwind
// css) or Vue + tailwind. Tailwind itself and the turbo-mount wrapper-div CSS
// rule are loaded from vitecss.css (a real blocking <link>, not a JS import
// here) so they're in effect before first paint — see that file's header.
//
// Registers every Vue 3 "island" mounted via the `turbo_mount` ERB helper
// (see app/frontend/lib/turboMount.ts and the "turbo-mount spike result"
// memory).
//
// To add a new component:
//   1. Add its Vue 3 SFC under app/frontend/components/.
//   2. Register it below — eager if it renders on essentially every page
//      (see EAGER_COMPONENTS), lazy otherwise.
//   3. In the ERB, render `<%= turbo_mount "<Name>", props: {...} %>`.
//
// The older `frontend_mount`/islands.ts mounter (app/helpers/frontend_helper.rb,
// app/frontend/lib/islands.ts) has no remaining call sites as of the full
// migration to turbo-mount — left in place, unused, pending a follow-up
// cleanup pass rather than deleted here.
//
// See: upgrade-plan/frontend/14-architecture-and-design.md

// These five render on essentially every page (banner/nav/search bar/download
// modal/cookie banner in the shared layout) — lazy-loading something that's
// never actually skipped buys nothing, it just adds a network round-trip
// before it can mount. Static imports bundle them straight into this
// entrypoint's own chunk instead.
// Turbo Drive: intercepts same-origin link clicks/form submits and swaps the
// <body> via fetch instead of a full page reload. Stimulus (which turbo-mount
// is built on) already handles island mount/unmount across that swap; see
// turboMount.ts and useAnalytics.ts for the two places that needed to adapt.
import '@hotwired/turbo-rails'

import Banner from '@/components/Banner/Index.vue'
import NavBar from '@/components/NavBar/Index.vue'
import SearchSiteTopbar from '@/components/Search/SiteTopbar.vue'
import DownloadModal from '@/components/Download/Modal.vue'
import CookieConsent from '@/components/CookieConsent.vue'

import { registerTurboMountComponents } from '@/lib/turboMount'
import { installTurboErrorResponseHandler } from '@/lib/turboErrorResponses'
import useAnalytics from '@/composables/useAnalytics'

// Resumes optional tracking (GA4/Hotjar) for visitors who already accepted cookies
// on a previous visit — the CookieConsent island only fires on the first decision.
useAnalytics().initAnalytics()

// Turbo renders non-2xx responses with ErrorRenderer, which replaces the entire
// <head> and so wipes every JS-injected component stylesheet. Make error pages a
// real browser navigation instead — see the lib file for the full explanation.
installTurboErrorResponseHandler()

registerTurboMountComponents({
  Banner: () => Promise.resolve({ default: Banner }),
  NavBar: () => Promise.resolve({ default: NavBar }),
  SearchSiteTopbar: () => Promise.resolve({ default: SearchSiteTopbar }),
  DownloadModal: () => Promise.resolve({ default: DownloadModal }),
  CookieConsent: () => Promise.resolve({ default: CookieConsent }),

  // Everything below is page-specific — stays lazy, only fetched when a page
  // actually renders it (see turboMount.ts's DOM-scan for why that matters).
  Tabs: () => import('@/components/Tabs.vue'),
  Download: () => import('@/components/Download/Index.vue'),
  GaLink: () => import('@/components/GaLink.vue'),
  Counter: () => import('@/components/Counter.vue'),
  ListingPageCardNews: () => import('@/components/ListingPageCard/News/Index.vue'),
  ListingPageCardResources: () => import('@/components/ListingPageCard/Resources/Index.vue'),
  Tooltip: () => import('@/components/Tooltip/Index.vue'),
  TooltipSecond: () => import('@/components/Tooltip/Second.vue'),
  Listing: () => import('@/components/Listing/Index.vue'),
  Map: () => import('@/components/Map/Index.vue'),
  SearchAreasPage: () => import('@/components/SearchAreas/Page.vue'),
  SearchAreas: () => import('@/components/SearchAreas/Index.vue'),
  RegionCountryPages: () => import('@/components/RegionCountryPages/Index.vue'),
  StatsTooltipInfo: () => import('@/components/Stats/TooltipInfo.vue'),
  StatsSites: () => import('@/components/Stats/Sites.vue'),
  ChartTotalCoverageChart: () => import('@/components/Chart/TotalCoverageChart.vue'),
  AmChartMultiline: () => import('@/components/AmChart/Multiline.vue'),
  AttributesParcelsDropdown: () => import('@/components/Dropdown/ParcelsDropdown.vue'),
  AttributesProtectedArea: () => import('@/components/Attributes/ProtectedArea/Index.vue'),
  AttributesPameList: () => import('@/components/Attributes/Pame/List.vue'),
  AttributesAffiliations: () => import('@/components/Attributes/Affiliations/Index.vue'),
  AttributesProtectedAreaSources: () => import('@/components/Attributes/ProtectedArea/Source/List.vue'),
  PameTable: () => import('@/components/Pame/Table/Index.vue'),
  CarouselThemes: () => import('@/components/Carousel/Themes/Index.vue'),
  CardsThemes: () => import('@/components/Cards/Themes/Index.vue'),
  SearchSite: () => import('@/components/Search/Index.vue')
})
