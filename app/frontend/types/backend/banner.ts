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
