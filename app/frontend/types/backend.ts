// Shape of a single row from the `banners` table, serialised via ActiveRecord's
// default `to_json` (no custom serializer — see app/models/banner.rb). Rendered by
// app/views/layouts/partials/_banner.html.erb through `frontend_mount "Banner"`.
export interface Banner {
  id: number
  title: string | null
  content: string
  is_active: boolean
  created_at: string
  updated_at: string
}

// Props passed to the `Banner` mount by `_banner.html.erb`.
export interface BannerProps {
  banners: Banner[]
  // SHA1 hex digest of the visible banners' ids — used to key the "closed" cookie
  // for the carousel case (see FrontendHelper#banner_signature).
  signature: string
}

// Props for `Counter`, a count-up-on-scroll-into-view number display.
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
