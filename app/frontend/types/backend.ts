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

// Props for `ChartRowPa` — a single labelled bar (coverage % within a total %),
// mounted directly inside partials/charts/_chart-row-pa.html.erb (marine ocean
// coverage, Green List tab) with the surrounding title/content/legend left as
// plain ERB since only the bar itself is dynamic/animated.
// `coverage`/`percent` are numeric on the Rails side (GlobalStatistic-derived
// percentages) — unlike the Vue2 original, where every ERB attribute was
// coerced to a string, `frontend_mount` sends the Ruby value's native JSON
// type straight through, so both callers here can produce a number.
export interface ChartRowPaProps {
  coverage: number | string
  percent: number | string
  theme?: string
}

// One row of `ChartRowStacked` — TabPresenter#designations' `designation_percentages`.
export interface ChartRowStackedRow {
  percent: number
}

export interface ChartRowStackedProps {
  title?: string
  theme?: string
  rows: ChartRowStackedRow[]
}

// One entry of AmChartPie's `dataset` — CountryPresenter/RegionPresenter's
// `iucn_categories_chart`/`governance_chart`.
export interface AmChartPieDatum {
  id: number | string
  title: string
  value: number
}

export interface AmChartPieProps {
  dataset: AmChartPieDatum[]
  doughnut?: boolean
  spacers?: boolean
}

// One datapoint of `AmChartMultiline`'s `data.datapoints` — numeric series keys
// ("1"/"2"/"3") are threaded straight from Thematic::MarineController's CSV
// parse, `x` is the date axis value.
export interface AmChartMultilineDatapoint {
  x: string
  [seriesIndex: string]: number | string
}

// Props for `frontend_mount "AmChartMultiline"` — mounted directly inside
// partials/charts/_chart-coverage-growth.html.erb (marine coverage growth),
// title/content left as plain ERB around the chart mount.
export interface AmChartMultilineProps {
  data: {
    units: string
    legend: string[]
    datapoints: AmChartMultilineDatapoint[]
  }
  dots?: boolean
  chartBackgroundColour?: string
}

// One item of TabPresenter#coverage (CountryPresenter/RegionPresenter#build_stats
// / #build_combined_stats) — snake_case straight from Rails, remapped to
// `StatsCoverageProps` (camelCase) by RegionCountryPages/Index.vue.
export interface StatsCoverageDatum {
  national_report_version?: number
  pame_km2?: string
  pame_percentage?: number
  protected_km2: string
  protected_national_report?: number
  protected_percentage: number
  text_coverage: string
  text_national_report?: string
  text_pame?: string
  text_pame_assessments?: string
  text_protected: string
  text_total: string
  title: string
  total_km2: string
  type: string
}

export interface StatsCoverageProps {
  nationalReportVersion?: number
  pameKm2?: string
  pamePercentage?: number
  protectedKm2: string
  protectedNationalReport?: number
  protectedPercentage: number
  textCoverage: string
  textNationalReport?: string
  textPame?: string
  textPameAssessments?: string
  textProtected: string
  textTotal: string
  title: string
  totalKm2: string
  type: string
}

// TabPresenter#message.
export interface StatsDocument {
  name: string
  url: string
  type: string
  button_text: string
}

export interface StatsMessageProps {
  documents?: StatsDocument[]
  link?: string
  text: string
}

// Shared link fields CountriesHelper#chart_link merges onto iucn/governance/
// designation-jurisdiction items — `title` here is a search-page tooltip title
// ("View the X sites for Y"), not a display label.
export interface StatsChartLink {
  link: string
  title?: string
}

export interface StatsIucnCategory extends StatsChartLink {
  iucn_category_name: string
  count: number
  percentage: number
}

// TabPresenter#iucn.
export interface StatsIucnCategoriesProps {
  categories: StatsIucnCategory[]
  chart: AmChartPieDatum[]
  title: string
}

// Raw TabPresenter#iucn shape — also carries `country` (unused by the
// component; TabPresenter builds it for every geo-entity type), picked down
// to StatsIucnCategoriesProps by RegionCountryPages/Index.vue instead of
// spread wholesale, so `country` doesn't fall through onto the DOM.
export interface StatsIucnCategoriesData extends StatsIucnCategoriesProps {
  country?: string
}

export interface StatsGovernanceType extends StatsChartLink {
  governance_name: string
  count: number
}

// TabPresenter#governance.
export interface StatsGovernanceProps {
  governance: StatsGovernanceType[]
  chart: AmChartPieDatum[]
  title: string
}

// Raw TabPresenter#governance shape — see StatsIucnCategoriesData above for
// why `country` is picked out rather than spread wholesale.
export interface StatsGovernanceData extends StatsGovernanceProps {
  country?: string
}

// TabPresenter#sources.
export interface StatsSourceItem {
  title: string
  date_updated: string
  resp_party: string
}

export interface StatsSourcesProps {
  count: number
  sourceUpdated: string
  sources: StatsSourceItem[]
  title: string
}

export interface StatsDesignationJurisdiction extends StatsChartLink {
  designation_name: string
  count: number
}

export interface StatsDesignationItem {
  title: string
  total: number
  has_jurisdiction?: boolean
  jurisdictions?: StatsDesignationJurisdiction[]
}

// TabPresenter#designations.
export interface StatsDesignationsProps {
  chart: ChartRowStackedRow[]
  designations: StatsDesignationItem[]
  title: string
}

export interface StatsSiteDetail {
  name: string
  site_id: number | string
  thumbnail_link: string
}

// TabPresenter#sites.
export interface StatsSitesProps {
  siteDetails: StatsSiteDetail[]
  textViewAll: string
  title: string
  viewAll: string
}

// One entry of `frontend_mount "RegionCountryPages"`'s `data` hash — keyed by
// database id ('wdpa'/'wdpa_oecm'), built by CountryController#build_hash /
// TabPresenter. `growth` (TabPresenter#growth) is omitted — its only consumer,
// StatsGrowth/AmChartLine (ticket #265), was removed as dead code.
export interface RegionCountryPagesDatabase {
  coverage?: StatsCoverageDatum[]
  message: StatsMessageProps
  iucn?: StatsIucnCategoriesData
  governance?: StatsGovernanceData
  sources?: StatsSourcesData
  designations?: StatsDesignationsProps
  sites?: StatsSitesData
}

// Raw (snake_case) shapes for the two `RegionCountryPagesDatabase` entries that
// need remapping to camelCase component props (sources → StatsSourcesProps,
// sites → StatsSitesProps) inside RegionCountryPages/Index.vue.
export interface StatsSourcesData {
  count: number
  source_updated: string
  sources: StatsSourceItem[]
  title: string
}

export interface StatsSitesData {
  site_details: StatsSiteDetail[]
  text_view_all: string
  title: string
  view_all: string
}

export interface RegionCountryPagesTab {
  id: string
  title: string
}

// Props for `frontend_mount "RegionCountryPages"` (country#show / region#show).
export interface RegionCountryPagesProps {
  data: Record<string, RegionCountryPagesDatabase>
  gaId?: string
  // Rendered HTML of partials/stats/_stats-related-countries.html.erb (country
  // page only) — replaces the legacy `related_countries` Vue2 slot, since
  // `frontend_mount` has no slot-content equivalent. Trusted server-rendered
  // markup, not user input.
  relatedCountriesHtml?: string
  tabs: RegionCountryPagesTab[]
}

// Props for `StatsTooltipInfo` — the WDPA/OECM info tooltip in
// partials/stats/_stats-overview-country.html.erb, replacing the legacy
// `<tooltip-second>` + ERB-in-slot markup (see Pattern B note in
// 14-architecture-and-design.md) with a single props-driven island.
export interface StatsTooltipInfoProps {
  description: string
  designationsLabel: string
  designationsCount: number
}

// PA show `attributes-*` family (Wave 9). Shared `forPdf` flag switches every
// island between "current selected parcel only" (site view) and "every
// parcel, one section each" (PDF export) — selection itself is read from the
// `site_pid` URL param via `useParcelSelection`, not passed as a prop.

// ProtectedAreasHelper#attributes_parcels_dropdown_descriptions.
export interface AttributesParcelsDropdownProps {
  title: string
  description?: string
  dropdownTitle?: string
  sitePids: string[]
  forPdf: boolean
}

// ProtectedAreaPresenter#current_pa_and_parcels_attributes entry.
export interface AttributesAttributeItem {
  title: string
  value: string
  is_site_pid?: boolean
}

export interface AttributesParcelAttributeSet {
  site_pid: string
  attributes: AttributesAttributeItem[]
}

export interface AttributesProtectedAreaProps {
  title: string
  forPdf: boolean
  attributesList: AttributesParcelAttributeSet[]
}

// ProtectedAreasHelper#current_pa_and_all_parcels_pame_evaluations_attributes:
// { site_pid => { method => [years...] } }.
export type AttributesPameYearsByMethod = Record<string, (string | number)[]>

export interface AttributesPameListTranslations {
  no_information: string
}

export interface AttributesPameListProps {
  pamesAttributesList: Record<string, AttributesPameYearsByMethod>
  title: string
  subTitle?: string
  forPdf: boolean
  translations: AttributesPameListTranslations
}

// ProtectedAreaPresenter#affiliations entry.
export interface AttributesAffiliationLink {
  site_pid: string
  affiliation: string
  image_url: string
  image_alt?: string
  link_url: string
  link_title: string
  type?: string
  date?: string
  url?: string
}

export interface AttributesAffiliationsTranslations {
  green_list_intro: string
  green_list_type: string
  green_list_date: string
  green_list_title: string
  green_list_url: string
  no_information: string
  more: string
}

export interface AttributesAffiliationsProps {
  affiliations: AttributesAffiliationLink[]
  title: string
  subTitle?: string
  forPdf: boolean
  translations: AttributesAffiliationsTranslations
}

// ProtectedArea#sources_attributes_for_current_pa_and_all_parcels:
// { site_pid => StatsSourceItem[] }.
export interface AttributesProtectedAreaSourcesTranslations {
  title: string
  total: string
  updated: string
}

export interface AttributesProtectedAreaSourcesProps {
  sourcesAttributesList: Record<string, StatsSourceItem[]>
  forPdf: boolean
  subTitle?: string
  translations: AttributesProtectedAreaSourcesTranslations
}

// PameEvaluation::TABLE_ATTRIBUTES entry (column definitions for the gdpame
// filtered table — `title` is the header, `tooltip` only present on one column).
export interface PameTableAttribute {
  title: string
  field: string
  tooltip?: string
}

// PameEvaluation.filters_to_json entry — plain string options, unlike
// ListingFilter/SearchFilter's `{id, title}` shape, since the values here ARE
// the filter values sent back in `PameFilterSelection.options` (method names,
// country names, years-as-strings, etc.).
export interface PameFilter {
  name: string
  title: string
  options: string[]
  type: string
}

// One entry of the `filters` array sent to/from `/pame/list` and `/pame/download`
// (PameEvaluation.parse_filters reads `name`/`options`).
export interface PameFilterSelection {
  name: string
  options: Array<string | number>
  type?: string
}

// PameEvaluation.serialise entry (one row of the gdpame table / PameModal detail).
export interface PameEvaluationItem {
  id: number
  asmt_id: string
  site_id: number | null
  site_pid: string | null
  pa_site_url: string
  country: string[]
  method: string | null
  asmt_year: string
  asmt_url: string
  eff_metaid: number | null
  source_id: number | null
  name: string
  designation: string
  data_title: string | null
  resp_party: string | null
  language: string | null
  source_year: number | null
}

// PameEvaluation.structure_data — shape returned by `/pame/list` and the
// initial `@json` prop from Data::GdpameController#index.
export interface PameTablePage {
  current_page: number
  per_page: number
  total_entries: number
  total_pages: number
  items: PameEvaluationItem[]
}

// I18n `thematic_area.pame.modal` — Data::GdpameController#index /
// views/data/gdpame/_tab_content.html.erb.
export interface PameModalTranslations {
  modal_title: string
  id: string
  title: string
  responsible: string
  year: string
  language: string
}

// Props for `Pame/Modal.vue`, rendered by `Pame/Table/Index.vue` as a normal
// child (not its own `frontend_mount` — it only ever appears alongside the
// table, and shares `usePameStore` with it).
export interface PameModalProps {
  text: PameModalTranslations
}

// Props for `frontend_mount "PameTable"` (Data::GdpameController#index, via
// partials/data/gdpame/_tab_content).
export interface PameTableProps {
  endpoint: string
  filters: PameFilter[]
  attributes: PameTableAttribute[]
  json: PameTablePage
  modalText: PameModalTranslations
}
