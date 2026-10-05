// Registers every Vue 3 island mounted via the `turbo_mount` ERB helper (see
// lib/turboMount.ts). Despite the name, turbo-mount is Stimulus-only: this app
// has no Turbo Drive, so every navigation is a full document load and this
// module is evaluated exactly once per page.
//
// Tailwind and the turbo-mount wrapper-div rule load from vitecss.css as a
// blocking <link>, not from here, so they apply before first paint.
//
// To add a component: put its SFC under app/frontend/components/, register it
// below (eager only if it renders on nearly every page), then render
// `<%= turbo_mount "<Name>", props: {...} %>` in the ERB.
//
// See: upgrade-plan/frontend/14-architecture-and-design.md

// These five are in the shared layout, so they render on nearly every page.
// Static imports bundle them into this entrypoint's chunk — lazy-loading
// something never skipped only adds a round-trip before it can mount.
import Banner from '@/components/Banner/Index.vue'
import NavBar from '@/components/NavBar/Index.vue'
import SearchSiteTopbar from '@/components/Search/SiteTopbar.vue'
import DownloadModal from '@/components/Download/Modal.vue'
import CookieConsent from '@/components/CookieConsent.vue'

import { registerTurboMountComponents } from '@/lib/turboMount'
import useAnalytics from '@/composables/useAnalytics'

// Resumes GA4/Hotjar for visitors who accepted on a previous visit — the
// CookieConsent island only fires on the first decision.
useAnalytics().initAnalytics()

registerTurboMountComponents({
  Banner: () => Promise.resolve({ default: Banner }),
  NavBar: () => Promise.resolve({ default: NavBar }),
  SearchSiteTopbar: () => Promise.resolve({ default: SearchSiteTopbar }),
  DownloadModal: () => Promise.resolve({ default: DownloadModal }),
  CookieConsent: () => Promise.resolve({ default: CookieConsent }),

  // Page-specific: stays lazy, fetched only when a page renders it (see the
  // DOM scan in turboMount.ts).
  //
  // Register a component here ONLY if an ERB view mounts it by name. A component
  // used solely as a child of another SFC needs a plain import in that parent, not
  // an entry here — `Tooltip` and `TooltipSecond` were both registered without any
  // `turbo_mount` calling for them (their real consumers are Pame/Table/Head/Cell
  // and Stats/TooltipInfo, which import them directly), so each was carrying its
  // own redundant chunk. Cross-check with:
  //   grep -rhoE 'turbo_mount "[A-Za-z]+"' app/views | sort -u
  Tabs: () => import('@/components/Tabs.vue'),
  Download: () => import('@/components/Download/Index.vue'),
  GaLink: () => import('@/components/GaLink.vue'),
  Counter: () => import('@/components/Counter.vue'),
  ListingPageCardNews: () => import('@/components/ListingPageCard/News/Index.vue'),
  ListingPageCardResources: () => import('@/components/ListingPageCard/Resources/Index.vue'),
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
