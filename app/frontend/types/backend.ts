import type { MapLayer } from '@/composables/useMapLayers'
import type { MapOptionsPayload, PointQueryService, PopupAttributeLabels } from '@/types/map'
import type { BoundsUrl } from '@/composables/useMapBoundingBox'

export interface Banner {
  id: number
  title: string | null
  content: string
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface BannerProps {
  banners: Banner[]
  // SHA1 hex digest of the visible banners' ids — used to key the "closed" cookie
  // for the carousel case (see FrontendHelper#banner_signature).
  signature: string
}

export interface CounterConfig {
  speed: number
  divisor: number
}

export interface CounterProps {
  config?: CounterConfig
  decimal?: number
  total: number
  // Class name of the element that triggers the count-up once it scrolls into view.
  trigger: string
  animate?: boolean
}

// Props for `GaLink`, rendered wherever a link needs a GA click event
// (see app/frontend/lib/analytics.ts). `text` carries the link's HTML label since
// a `frontend_mount` island has no server-rendered slot content to project into.
export interface GaLinkProps {
  gaId?: string
  href: string
  text: string
}

// Props for `listing-page-card-news`, rendered by
// app/views/partials/cards/_articles.html.erb.
export interface ListingPageCardNewsProps {
  date?: string
  image?: string
  summary?: string
  title: string
  url: string
}

// Props for `listing-page-card-resources`, rendered by
// app/views/partials/cards/_resources.html.erb.
export interface ListingPageCardResourcesProps {
  date?: string
  fileUrl?: string
  linkTitle?: string
  linkUrl?: string
  summary?: string
  title: string
  url?: string
}

// Props for the `listing-page-card-news`/`listing-page-card-resources` list
// wrappers — one mount per `cards__cards` grid, rendering a `Card` per item.
export interface ListingPageCardNewsListProps {
  cards: ListingPageCardNewsProps[]
}

export interface ListingPageCardResourcesListProps {
  cards: ListingPageCardResourcesProps[]
  preview?: boolean
}

// Shape produced by ApplicationHelper#map_page (used by #get_nav_primary),
// passed as the `links` prop to the `NavBar` island (frontend_mount "NavBar").
// See app/helpers/application_helper.rb.
export interface NavLink {
  id: string
  label: string
  url: string
  is_current_page: boolean
  children?: NavLink[]
}

// Props for `frontend_mount "SearchSiteTopbar"` — see _topbar.html.erb.
export interface SearchSiteTopbarProps {
  endpoint: string
  placeholder: string
}

// Anticipated shape for a `frontend_mount "Tabs"` prop payload. No Rails code
// builds this yet (Tabs.vue is not wired to a live page — see Tabs.vue header
// comment); this is the contract the first real tab-page migration should produce.
export interface Tab {
  id: number
  // HTML allowed — rendered with v-html.
  title: string
  // Trusted CMS copy for the tab, rendered with v-html when present.
  bodyHtml?: string
}

export interface TabsProps {
  tabs: Tab[]
  // Matches by id or by title, mirroring the legacy `?tab=` query param.
  preselectedTab?: number | string | null
  // GA event label prefix, e.g. "Slug: about-us". Omit to skip tracking.
  gaId?: string
}

// One entry of DownloadsHelper::DEFAULT_OPTIONS merged with #download_params,
// passed to `Download` (`frontend_mount "Download"`) as `options`.
export interface DownloadOption {
  isDownload?: boolean
  isMap?: boolean
  title: string
  commercialAvailable?: boolean
  url?: string
  params?: {
    domain: string
    format: string
    token: string
    // Attached for the 'search' domain option — see Download/Index.vue's
    // clickNonCommercial, sourced from useDownloadStore's search bridge.
    filters?: unknown
    search?: string
  }
}

export interface DownloadProps {
  buttonText: string
  options: DownloadOption[]
  // See DownloadsHelper#download_text[:commercial].
  textCommercial: {
    commercialText: string
    commercialTitle: string
    nonCommercialText: string
    nonCommercialTitle: string
    nonCommercialButton: string
    title: string
  }
  downloadDisabled?: boolean
  gaId: string
}

// Props for `DownloadModal` (`frontend_mount "DownloadModal"`, mounted once
// globally in application.html.erb).
export interface DownloadModalProps {
  endpointCreate: string
  endpointPoll: string
  gaId: string
  // See DownloadsHelper#download_text[:download].
  textDownload: {
    citationText: string
    citationTitle: string
    title: string
  }
  // See DownloadsHelper#download_text[:status].
  textStatus: {
    download: string
    failed: string
    generating: string
  }
}

// One item from Search::CmsSerializer#serialize (SearchCmsController#index,
// and the initial page load via SearchHelper#cms_pages_for_search).
export interface ListingResult {
  date?: string
  fileUrl?: string
  linkUrl?: string
  // Serializer bug: the JSON key is actually `linktTile` (typo), so this is
  // always undefined in practice — pre-existing on the backend, not a
  // regression introduced by this migration.
  linkTitle?: string
  title: string
  url?: string
  summary?: string
  image?: string
}

export interface ListingResults {
  total: number
  totalPages: number
  results: ListingResult[]
}

// Shared shape for Filters/Checkboxes' options — kept broad (id can be a
// number) because CmsHelper#get_category_filters sources ListingFilterOption
// from Comfy::Cms::PageCategory#id (an integer primary key), not a string slug.
export interface FilterOption {
  id: string | number
  title: string
}

export type ListingFilterOption = FilterOption

// Only `type: 'checkbox'` is ever sent for the news/resources listing pages
// (see CmsHelper#get_category_filters) — `radio`/`checkbox-search` are only
// used by the still-Vue2 search-areas filters (Search::FiltersSerializer).
export interface ListingFilter {
  id: string
  title?: string
  type: 'checkbox'
  options: ListingFilterOption[]
}

export interface ListingFilterGroup {
  title?: string
  filters: ListingFilter[]
}

// Props for `MapBase` (the bare MapLibre instance, no panel/disclaimer/header) —
// see home_controller.rb.
export interface MapBaseProps {
  options?: MapOptionsPayload
  servicesForPointQuery?: PointQueryService[]
  popupAttributes?: PopupAttributeLabels
}

// One entry of MapOverlaysSerializer#serialize (MapHelper::OVERLAYS), rendered as an
// item of `MapPanelProps['overlays']` — see home_controller.rb's `@main_map[:overlays]`.
export interface MapFilterProps {
  color?: string
  title: string
  isShownByDefault?: boolean
  isToggleable?: boolean
  layers: MapLayer[]
  id: string
  type: string
}

// `map_yml[:disclaimer]` (config/locales/map/*.yml) — passed as `disclaimer` to
// `MapPanel`, forwarded to `MapDisclaimer` (rendered inside the panel, always in
// the same place, for every page — no per-page slotting/placement variance).
export interface MapDisclaimerProps {
  disclaimer?: { heading: string, body: string } | null
}

// Props for `frontend_mount "MapPanel"` (formerly "MapFilters") — see
// home_controller.rb's `@main_map`. Renders `MapDisclaimer` internally.
export interface MapPanelProps {
  overlays: MapFilterProps[]
  title: string
  isHidden?: boolean
  disclaimer?: { heading: string, body: string } | null
  // The PA-search box (`MapPaSearch`) only appears when these are provided —
  // omitted on the header-map layout, which has no search box. See
  // `Autocompletion.get_filters` for the `type` values.
  type?: string
  autocompleteErrorMessages?: AutocompleteErrorMessages
  autocompletePlaceholder?: string
}

// Props for `frontend_mount "Map"` — the single top-level map composition
// (MapBase + MapPanel, MapPanel rendering MapDisclaimer internally) used by
// every page that shows a map, identically. See partials/maps/_main.html.erb /
// partials/maps/_header.html.erb for the legacy Vue2 equivalents this replaces.
export interface MapProps {
  options?: MapOptionsPayload
  servicesForPointQuery?: PointQueryService[]
  popupAttributes?: PopupAttributeLabels
  title: string
  overlays: MapFilterProps[]
  disclaimer?: { heading: string, body: string } | null
  isHidden?: boolean
  // Set false for the "map--header" layout (protected_areas/show, region/show,
  // country/show) — those pages show the panel toggle but no standalone map title.
  showHeader?: boolean
  // The PA-search box (`MapPaSearch`, rendered inside `MapPanel`) only appears
  // when these are provided — omitted on the header-map layout, which has no
  // search box. See `Autocompletion.get_filters` for the `type` values.
  type?: string
  autocompleteErrorMessages?: AutocompleteErrorMessages
  autocompletePlaceholder?: string
}

// Props for `MapPaSearch` — the "search & jump to a PA/country/region on the
// map" box. Not its own `frontend_mount` entry: `MapPanel` renders it directly
// (as a normal child component) when `type`/autocomplete-copy props are
// present, threaded through `MapPanelProps`/`MapProps` above. See
// `partials/maps/_main.html.erb`'s `<v-map-pa-search>` for the legacy Vue2 tag
// this replaces.
export interface MapPaSearchProps {
  autocompleteErrorMessages: AutocompleteErrorMessages
  autocompletePlaceholder: string
  type: string
}

export interface AutocompleteErrorMessages {
  no_results: string
  invalid_search_string: string
}

// One item of `SearchController#autocomplete`'s JSON (`Autocompletion.lookup`) —
// `POST /search/autocomplete`.
export interface AutocompleteResult {
  id: string | number
  is_pa: boolean
  // Only set when is_pa — a region/country result has no site_pid.
  site_pid: string | null
  extent_url: BoundsUrl
  title: string
  url: string
}

// Props for `frontend_mount "Listing"` — the news/resources listing pages
// (filters + ajax pagination). Rendered by
// app/views/layouts/cms/{_news-and-stories,_resources}.html.erb.
export interface ListingProps {
  endpointSearch: string
  filterGroups: ListingFilterGroup[]
  gaId: string
  itemsPerPage?: number
  pageId: number
  results: ListingResults
  template: 'news' | 'resources'
  textClear: string
  textFiltersClose: string
  textFilterTrigger: string
  textNoResults: string
}

// One item of Search::AreasSerializer#serialize's `areas` array — shape
// differs slightly per `geoType` (region/country hashes carry `countryFlag`/
// `totalAreas`, a site hash carries neither), so every field but the shared
// `image`/`title`/`url` is optional here rather than a discriminated union.
export interface SearchAreaResult {
  title: string
  url: string
  image?: string
  countryFlag?: string
  totalAreas?: string
}

// Search::AreasSerializer#serialize — one geo-type "page" of area search
// results (site/country/region), passed as `results` to `frontend_mount
// "SearchAreas"` and returned by SearchAreasController#search_results as
// `{ areas: ... }`.
export interface SearchAreasResults {
  geoType: string
  title: string
  total: number
  totalPages: number
  areas: SearchAreaResult[]
}

// One option of a Search::FiltersSerializer filter — `autocomplete` is only
// present on the `location` filter's `country`/`region` options (type
// `checkbox-search`).
export interface SearchFilterOption extends FilterOption {
  id: string
  autocomplete?: SearchFilterOption[]
}

// One entry of Search::FiltersSerializer#serialize's `filters` array.
export interface SearchFilter {
  id: string
  name?: string
  title?: string
  type: 'checkbox' | 'radio' | 'checkbox-search'
  options: SearchFilterOption[]
  // Set by SearchAreas/Index.vue from the `?filters[...]` query string before
  // handing filterGroups down to Filters/Index.vue — not part of the
  // serializer's own JSON.
  preSelected?: string[] | [{ type: string, options: string[] }]
}

export interface SearchFilterGroup {
  title: string
  filters: SearchFilter[]
}

// SearchAreasController#index's `@config_search_areas` / the home page's
// `config` (partials/search/_protected-areas.html.erb) — also read directly
// by `SearchAreasInputAutocomplete` for its POST body's `type`.
export interface SearchAreasConfig {
  id: string
  placeholder: string
}

// SearchAreasController#index's `@tabs` (geo_type switcher: region/country/site).
export interface SearchAreasTab {
  id: string
  title: string
}

// Props for `frontend_mount "SearchAreas"` (search_areas/index.html.erb).
// `downloadButtonText`/`downloadTextCommercial` are new here (Wave 7) — the
// legacy Vue2 version rendered `<Download>` via an ERB partial + `v-slot`
// (partials/download/_download.html.erb), which read `download_text`/
// `t('global.button.download')` itself; now that SearchAreas/Index.vue
// composes `Download` directly as a normal child, those two need threading
// through as props instead. See DownloadsHelper#download_text.
export interface SearchAreasProps {
  configAutocomplete: SearchAreasConfig
  downloadButtonText: string
  downloadOptions: DownloadOption[]
  downloadTextCommercial: DownloadProps['textCommercial']
  endpointAutocomplete: string
  endpointSearch: string
  filterGroups: SearchFilterGroup[]
  gaId: string
  noResultsText: string
  results: SearchAreasResults
  smTriggerElement: string
  tabs: SearchAreasTab[]
  textClear: string
  textClose: string
  textFilters: string
}

// Props for `frontend_mount "SearchAreasHome"`
// (partials/search/_protected-areas.html.erb).
export interface SearchAreasHomeProps {
  config: SearchAreasConfig
  endpointAutocomplete: string
  endpointSearch: string
}
