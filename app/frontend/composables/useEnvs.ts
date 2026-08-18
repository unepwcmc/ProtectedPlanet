// Types for ViteRuby.env-sourced values (see config/vite.rb) exposed to client
// code via import.meta.env. Add a type here whenever a new VITE_ key is added there.
import type { Environment } from '@/constants/environment'

export type useEnvs = ImportMetaEnv & {
  readonly VITE_MAPBOX_TOKEN: string
  readonly VITE_RAILS_ENV: Environment
}

export default function () {
  return import.meta.env as useEnvs
}
