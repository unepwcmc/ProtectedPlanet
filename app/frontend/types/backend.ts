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
  // Keys the "closed" cookie — FrontendHelper#banner_signature.
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
  // Class of the element whose scroll-into-view starts the count-up.
  trigger: string
  animate?: boolean
}

// A link with a GA click event (useAnalytics.ts). `text` is the HTML label —
// turbo_mount islands have no slot content.
export interface GaLinkProps {
  gaId?: string
  href: string
  text: string
}

// Copy from config/locales/global/en.yml. `description` is HTML (carries the
// Privacy policy link).
export interface CookieConsentProps {
  description: string
  accept: string
  reject: string
}

// partials/cards/_articles.html.erb.
export interface ListingPageCardNewsProps {
  date?: string
  image?: string
  summary?: string
  title: string
  url: string
}

// partials/cards/_resources.html.erb.
export interface ListingPageCardResourcesProps {
  date?: string
  fileUrl?: string
  linkTitle?: string
  linkUrl?: string
  summary?: string
  title: string
  url?: string
}

// One mount per `cards__cards` grid, rendering a `Card` per item.
export interface ListingPageCardNewsListProps {
  cards: ListingPageCardNewsProps[]
}

export interface ListingPageCardResourcesListProps {
  cards: ListingPageCardResourcesProps[]
  preview?: boolean
}

// ApplicationHelper#map_page, via #get_nav_primary — NavBar's `links` prop.
export interface NavLink {
  id: string
  label: string
  url: string
  is_current_page: boolean
  children?: NavLink[]
}

// partials/_topbar.html.erb.
export interface SearchSiteTopbarProps {
  endpoint: string
  placeholder: string
}

// ThematicAndDataAreaHelper#thematic_and_data_area_vue_tabs.
export interface Tab {
  id: number
  // Rendered with v-html.
  title: string
  // Trusted CMS copy, rendered with v-html.
  bodyHtml?: string
}

export interface TabsProps {
  tabs: Tab[]
  // Matches by id or title, mirroring the `?tab=` query param.
  preselectedTab?: number | string | null
  // GA label prefix, e.g. "Slug: about-us". Omit to skip tracking.
  gaId?: string
}

// DownloadsHelper::DEFAULT_OPTIONS merged with #download_params.
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
    // 'search' domain only — from useDownloadStore, see Download/Index.vue.
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

// Mounted once globally in application.html.erb.
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

// Search::CmsSerializer#serialize — SearchCmsController#index, and the initial
// load via SearchHelper#cms_pages_for_search.
export interface ListingResult {
  date?: string
  fileUrl?: string
  linkUrl?: string
  // Always undefined: the serializer emits `linktTile` (pre-existing typo).
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

// Filters/Checkboxes options. `id` allows number because
// CmsHelper#get_category_filters uses Comfy::Cms::PageCategory#id.
export interface FilterOption {
  id: string | number
  title: string
}

export type ListingFilterOption = FilterOption

// CmsHelper#get_category_filters only ever sends `checkbox`; the other types
// belong to the search-areas filters (Search::FiltersSerializer).
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

// What `Filters/Group.vue` accepts: the union of the CMS listing's filters
// (checkbox only, numeric Comfy category ids) and the search-areas serializer's
// (three widget types, string ids). Both `ListingFilter` and `SearchFilter` are
// assignable to it.
export interface FilterGroupFilter {
  id: string
  name?: string
  title?: string
  type: 'checkbox' | 'radio' | 'checkbox-search'
  options: FilterOption[]
  preSelected?: Array<string | number> | [{ type: string, options: string[] }]
}

// One group's current selection: option ids for checkbox/radio groups, and the
// {type, options} pair a checkbox-search group resolves to.
export type FilterGroupSelection = Array<string | number> | { type: string, options: string[] }

// The bare MapLibre instance — no panel, disclaimer or header.
export interface MapBaseProps {
  options?: MapOptionsPayload
  servicesForPointQuery?: PointQueryService[]
  popupAttributes?: PopupAttributeLabels
}

// MapOverlaysSerializer#serialize (MapHelper::OVERLAYS) — one `overlays` item.
export interface MapFilterProps {
  color?: string
  title: string
  isShownByDefault?: boolean
  isToggleable?: boolean
  layers: MapLayer[]
  id: string
  type: string
}

export type DisclaimerText = { heading: string, body: string } | null
// `map_yml[:disclaimer]` (config/locales/map/*.yml) — rendered directly below
// the map on every page.
export interface MapDisclaimerProps {
  disclaimer?: DisclaimerText
  mapiIsForRegionCountryPA: boolean
}

// Not a mount point — `Map` renders it, threaded through `MapProps`. Built by
// home_controller.rb's `@main_map`.
export interface MapPanelProps {
  overlays: MapFilterProps[]
  title: string
  isHidden?: boolean
  // `MapPaSearch` only renders when these are set (the header-map layout has
  // no search box). `type` values: Autocompletion.get_filters.
  type?: string
  autocompleteErrorMessages?: AutocompleteErrorMessages
  autocompletePlaceholder?: string
  disclaimer?: DisclaimerText
  mapiIsForRegionCountryPA?: boolean
}

// The top-level map composition (MapBase + MapDisclaimer + MapPanel) used by
// every page with a map.
export interface MapProps {
  options?: MapOptionsPayload
  servicesForPointQuery?: PointQueryService[]
  popupAttributes?: PopupAttributeLabels
  title: string
  overlays: MapFilterProps[]
  disclaimer?: DisclaimerText
  isHidden?: boolean
  // False on protected_areas/region/country show — those use the
  // disclaimer-only layout (isHidden) with no standalone map title.
  showHeader?: boolean
  // `MapPaSearch` only renders when these are set (the header-map layout has
  // no search box). `type` values: Autocompletion.get_filters.
  type?: string
  autocompleteErrorMessages?: AutocompleteErrorMessages
  autocompletePlaceholder?: string
  mapiIsForRegionCountryPA?: boolean
}

// The "jump to a PA/country/region" box. Not a mount point — `MapPanel`
// renders it when `type` and the autocomplete copy are present.
export interface MapPaSearchProps {
  autocompleteErrorMessages: AutocompleteErrorMessages
  autocompletePlaceholder: string
  type: string
}

export interface AutocompleteErrorMessages {
  no_results: string
  invalid_search_string: string
}

// POST /search/autocomplete — SearchController#autocomplete, via
// Autocompletion.lookup.
export interface AutocompleteResult {
  id: string | number
  is_pa: boolean
  // Only set when is_pa.
  site_pid: string | null
  extent_url: BoundsUrl
  title: string
  url: string
}

// The news/resources listing pages (filters + ajax pagination) —
// layouts/cms/{_news-and-stories,_resources}.html.erb.
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

// One item of Search::AreasSerializer#serialize's `areas`. Optional rather
// than a discriminated union: only region/country carry countryFlag/totalAreas.
export interface SearchAreaResult {
  title: string
  url: string
  image?: string
  countryFlag?: string
  totalAreas?: string
}

// Search::AreasSerializer#serialize — one geo-type page of results, also the
// `{ areas: ... }` body of SearchAreasController#search_results.
export interface SearchAreasResults {
  geoType: string
  title: string
  total: number
  totalPages: number
  areas: SearchAreaResult[]
}

// `autocomplete` is only on the `location` filter's country/region options.
export interface SearchFilterOption extends FilterOption {
  id: string
  autocomplete?: SearchFilterOption[]
}

// Search::FiltersSerializer#serialize's `filters` entry.
export interface SearchFilter {
  id: string
  name?: string
  title?: string
  type: 'checkbox' | 'radio' | 'checkbox-search'
  options: SearchFilterOption[]
  // Not from the serializer — SearchAreas/Page.vue sets it from `?filters[...]`.
  preSelected?: string[] | [{ type: string, options: string[] }]
}

export interface SearchFilterGroup {
  title: string
  filters: SearchFilter[]
}

// SearchAreasController#index's `@config_search_areas`, and the home page's
// `config`. `SearchAreasInputAutocomplete` reads `id` as its POST body `type`.
export interface SearchAreasConfig {
  id: string
  placeholder: string
}

// SearchAreasController#index's `@tabs` — the region/country/site switcher.
export interface SearchAreasTab {
  id: string
  title: string
}

// search_areas/index.html.erb. `downloadButtonText`/`downloadTextCommercial`
// are threaded through because Page.vue composes `Download` itself — see
// DownloadsHelper#download_text.
export interface SearchAreasPageProps {
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

// partials/search/_protected-areas.html.erb.
export interface SearchAreasProps {
  config: SearchAreasConfig
  endpointAutocomplete: string
  endpointSearch: string
}

// Search::FullSerializer#serialize's `results` entry.
export interface SearchSiteResult {
  title: string
  url: string
  summary?: string
  image?: string
}

// Search::FullSerializer#serialize — `SearchSite`'s `dataPageLoad`, and the
// body of SearchController#search_results.
export interface SearchSiteResultsData {
  searchTerm: string
  currentPage: number
  pageItemsStart: number
  pageItemsEnd: number
  totalItems: number
  results: SearchSiteResult[]
}

// SearchController#index's `@categories`.
export interface SearchSiteCategory {
  id: string
  title: string
}

// search/index.html.erb.
export interface SearchSiteProps {
  categories: SearchSiteCategory[]
  dataPageLoad: SearchSiteResultsData
  endpoint: string
  gaId?: string
  itemsPerPage?: number
  noResultsText: string
  placeholder: string
  resultsText: string
}

// One bar of `ChartTotalCoverageChart`. `legend_colour_class` is a
// `tw-shared-chart-legend-colour-*` class (styles/shared/themes.css) from the
// Rails helper; `title` doubles as the legend label.
export interface ChartTotalCoverageChartBar {
  legend_colour_class: string
  title: string
  value: number | string
}

// A "total" bar with a narrower "coverage" bar drawn inside it. Mounted inside
// partials/charts/_total-coverage-chart.html.erb; the title stays plain ERB.
export interface ChartTotalCoverageChartProps {
  total: ChartTotalCoverageChartBar
  coverage: ChartTotalCoverageChartBar
}

// TabPresenter#designations' `designation_percentages`.
export interface ChartRowStackedRow {
  percent: number
}

export interface ChartRowStackedProps {
  title?: string
  theme?: string
  rows: ChartRowStackedRow[]
}

// CountryPresenter/RegionPresenter's `iucn_categories_chart`/`governance_chart`.
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

// `AmChartMultiline`'s `data.datapoints`. `x` is the date axis; the numeric
// series keys come straight from Thematic::MarineController's CSV parse.
export interface AmChartMultilineDatapoint {
  x: string
  [seriesIndex: string]: number | string
}

// partials/charts/_chart-coverage-growth.html.erb; the surrounding
// title/content stays plain ERB.
export interface AmChartMultilineProps {
  data: {
    units: string
    legend: string[]
    datapoints: AmChartMultilineDatapoint[]
  }
  dots?: boolean
  chartBackgroundColour?: string
}

// TabPresenter#coverage — snake_case from Rails, remapped to
// `StatsCoverageProps` by RegionCountryPages/Index.vue.
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

// CountriesHelper#chart_link, merged onto iucn/governance/jurisdiction items.
// `title` is a tooltip ("View the X sites for Y"), not a display label.
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

// Raw TabPresenter#iucn. RegionCountryPages/Index.vue picks fields down to
// StatsIucnCategoriesProps rather than spreading, so `country` (unused) does
// not fall through onto the DOM.
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

// Raw TabPresenter#governance — see StatsIucnCategoriesData on `country`.
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

// TabPresenter#sites, or ApplicationHelper#site_card_details for a direct
// (non-RegionCountryPages) mount.
export interface StatsSitesProps {
  siteDetails: StatsSiteDetail[]
  textViewAll: string
  title: string
  viewAll: string
}

// One entry of RegionCountryPages' `data`, keyed by database id
// ('wdpa'/'wdpa_oecm') — CountryController#build_hash / TabPresenter.
// TabPresenter#growth is omitted: its only consumer was removed as dead code.
export interface RegionCountryPagesDatabase {
  coverage?: StatsCoverageDatum[]
  message: StatsMessageProps
  iucn?: StatsIucnCategoriesData
  governance?: StatsGovernanceData
  sources?: StatsSourcesData
  designations?: StatsDesignationsProps
  sites?: StatsSitesData
}

// The two `RegionCountryPagesDatabase` entries RegionCountryPages/Index.vue
// remaps to camelCase props (StatsSourcesProps / StatsSitesProps).
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

// country#show / region#show.
export interface RegionCountryPagesProps {
  data: Record<string, RegionCountryPagesDatabase>
  gaId?: string
  // Rendered partials/stats/_stats-related-countries.html.erb (country page
  // only) — trusted server markup, passed as a prop since turbo_mount has no
  // slot equivalent.
  relatedCountriesHtml?: string
  tabs: RegionCountryPagesTab[]
}

// The WDPA/OECM info tooltip in partials/stats/_stats-overview.html.erb —
// country#show only, gated on the *_national_designations_count locals.
export interface StatsTooltipInfoProps {
  description: string
  designationsLabel: string
  designationsCount: number
}

// PA show `attributes-*` family. `forPdf` switches every island between the
// selected parcel only (site view) and one section per parcel (PDF export).
// Selection comes from the `site_pid` URL param via `useParcelSelection`.

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

// ProtectedAreasHelper#current_pa_and_all_parcels_pame_evaluations_attributes.
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

// ProtectedArea#sources_attributes_for_current_pa_and_all_parcels.
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

// PameEvaluation::TABLE_ATTRIBUTES — a gdpame table column. `title` is the
// header; only one column has a `tooltip`.
export interface PameTableAttribute {
  title: string
  field: string
  tooltip?: string
}

// PameEvaluation.filters_to_json. Options are plain strings, not
// `{id, title}` — they are the values sent back in PameFilterSelection.
export interface PameFilter {
  name: string
  title: string
  options: string[]
  type: string
}

// The `filters` array for `/pame/list` and `/pame/download` —
// PameEvaluation.parse_filters reads `name`/`options`.
export interface PameFilterSelection {
  name: string
  options: Array<string | number>
  type?: string
}

// PameEvaluation.serialise — one gdpame table row / PameModal detail.
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

// PameEvaluation.structure_data — `/pame/list`, and Data::GdpameController's
// initial `@json`.
export interface PameTablePage {
  current_page: number
  per_page: number
  total_entries: number
  total_pages: number
  items: PameEvaluationItem[]
}

// I18n `thematic_area.pame.modal`.
export interface PameModalTranslations {
  modal_title: string
  id: string
  title: string
  responsible: string
  year: string
  language: string
}

// Data::GdpameController#index, via partials/data/gdpame/_tab_content.
export interface PameTableProps {
  endpoint: string
  filters: PameFilter[]
  attributes: PameTableAttribute[]
  json: PameTablePage
  modalText: PameModalTranslations
}

// ApplicationHelper#theme_cards_vue_props, from ThematicAreasPresenter —
// shared by the themes carousel and the CMS themes card grid. `pasNo` is -1
// when there is no protected-area count, which hides the ribbon.
export interface CarouselThemeCard {
  url: string
  linkTitle: string
  label: string
  imageUrl: string
  summary: string
  pasNo: number | string
  slug: string
}

// Shared by the `CarouselThemes` and `CardsThemes` mounts.
export interface CarouselThemesProps {
  cards: CarouselThemeCard[]
  areaTypeLabel: string
}

// One card plus the list-level `areaTypeLabel`. `featured` is grid-only
// (Cards/Themes/Index.vue, every 3rd card); the carousel keeps cards uniform.
export interface CarouselThemesCardProps extends CarouselThemeCard {
  areaTypeLabel: string
  featured?: boolean
}
