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
