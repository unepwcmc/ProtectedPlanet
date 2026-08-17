// TurboMount wiring for the `turbo_mount` ERB helper (see the "turbo-mount
// spike result" memory / upgrade-plan/frontend/14-architecture-and-design.md).
// Loaders are lazy (`() => import(...)`), same as islands.ts's IslandLoader —
// see below for why a DOM scan (not just calling every loader up front) is
// needed to actually keep that laziness.
import { TurboMount, buildRegisterFunction, type Plugin } from 'turbo-mount'
import { createApp, type Component } from 'vue'
import { pinia } from '@/stores/pinia'

export type TurboMountLoader = () => Promise<{ default: Component }>

// Why a custom Vue plugin instead of turbo-mount's stock `turbo-mount/vue`:
// islands.ts installs the app-wide `pinia` singleton into every island's own
// createApp() before mounting. turbo-mount's stock plugin doesn't do that, so
// any registered component that calls a Pinia store (e.g. Download's
// useDownloadStore()) throws "no active Pinia" as soon as turbo-mount is the
// ONLY mounter on a page (islands.ts happening to also be on the page was
// masking this in an earlier version of the pilot). Fix: wrap mounting so
// every component gets the same shared pinia via `app.use()`.
const piniaAwareVuePlugin: Plugin<Component> = {
  mountComponent({ el, Component: mounted, props }) {
    // turbo-mount types `props` as bare `object` (see MountComponentProps<T> in
    // turbo-mount's own .d.ts) — cast, same as islands.ts casts its mounted
    // component, to match Vue's createApp(component, props) signature.
    const app = createApp(mounted, props as Parameters<typeof createApp>[1])
    app.use(pinia)
    app.mount(el)
    return () => app.unmount()
  }
}

const registerComponent = buildRegisterFunction(piniaAwareVuePlugin)

const TURBO_MOUNT_SELECTOR = '[data-controller^="turbo-mount-"]'

/**
 * Register component name -> lazy component loader for turbo-mount.
 *
 * Calling every loader up front (e.g. `Object.values(map).forEach(l => l())`)
 * would defeat the whole point of lazy loaders: it downloads/parses/executes
 * EVERY registered component's JS chunk on EVERY page, not just the ones that
 * page actually renders — which is worse than islands.ts, not equivalent to
 * it. Instead, scan the DOM for the `turbo_mount(...)`-rendered host elements
 * that are actually present, read each one's real component name off its
 * `...-component-value` data attribute (turbo-mount kebab-cases that
 * attribute's NAME per component, but always keeps the PascalCase component
 * name as the VALUE — reading the value sidesteps needing to reimplement its
 * kebab-casing here), and only call that component's loader.
 *
 * A MutationObserver (same technique as islands.ts) keeps watching after the
 * initial scan: a turbo_mount div can enter the DOM later — e.g. nested
 * inside another island's `v-html` prop (a raw ERB-rendered HTML string,
 * itself containing a turbo_mount call, injected into an already-mounted
 * component) — see RegionCountryPages' `relatedCountriesHtml` prop for a real
 * example of that pattern. Only register a given name once, even if its
 * host element appears more than once (turbo-mount throws on a duplicate
 * register).
 */
export function registerTurboMountComponents(map: Record<string, TurboMountLoader>): void {
  const turboMount = new TurboMount()
  const registered = new Set<string>()

  function ensureRegistered(name: string): void {
    const loader = map[name]
    if (!loader || registered.has(name)) return
    registered.add(name)
    // Without this, a component whose chunk 404s or has a load-time error
    // (e.g. a bad import path) fails silently: its data-controller stays
    // registered as "seen" but never actually connects, so the mount point
    // just sits empty forever with nothing in the console to explain why.
    loader()
      .then(mod => registerComponent(turboMount, name, mod.default))
      .catch(e => console.error(`[turboMount] failed to load component "${name}"`, e))
  }

  function componentNamesOn(el: HTMLElement): string[] {
    return Object.entries(el.dataset)
      .filter(([key]) => key.endsWith('ComponentValue'))
      .map(([, value]) => value)
      .filter((value): value is string => !!value)
  }

  function scan(root: ParentNode): void {
    const hosts = root instanceof HTMLElement && root.matches(TURBO_MOUNT_SELECTOR)
      ? [root, ...root.querySelectorAll<HTMLElement>(TURBO_MOUNT_SELECTOR)]
      : Array.from(root.querySelectorAll<HTMLElement>(TURBO_MOUNT_SELECTOR))
    hosts.forEach(el => componentNamesOn(el).forEach(ensureRegistered))
  }

  scan(document)
  if (typeof MutationObserver === 'undefined' || !document.body) return
  new MutationObserver((mutations) => {
    mutations.forEach(mutation =>
      mutation.addedNodes.forEach((node) => {
        if (node instanceof HTMLElement) scan(node)
      })
    )
  }).observe(document.body, { childList: true, subtree: true })
}
