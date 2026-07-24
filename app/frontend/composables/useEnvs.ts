// Types for ViteRuby.env-sourced values (see config/vite.rb) exposed to client
// code via import.meta.env. Add a type here whenever a new VITE_ key is added there.
export type useEnvs = ImportMetaEnv & {
  readonly VITE_MAPBOX_TOKEN: string
}

export function useEnvs(): useEnvs {
  return import.meta.env as useEnvs
}

export default useEnvs
