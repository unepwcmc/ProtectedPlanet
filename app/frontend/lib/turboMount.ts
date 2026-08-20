// TurboMount wiring for the `turbo_mount` ERB helper (see the "turbo-mount
// spike result" memory / upgrade-plan/frontend/14-architecture-and-design.md).
// This is the only island mounter in the app. Loaders are lazy
// (`() => import(...)`) — see below for why a DOM scan (not just calling every
// loader up front) is needed to actually keep that laziness.
import { TurboMount, buildRegisterFunction, type Plugin } from 'turbo-mount'
import { createApp, type Component } from 'vue'
import { pinia } from '@/stores/pinia'
import { markIslandScanComplete } from '@/lib/pdfReady'

export type TurboMountLoader = () => Promise<{ default: Component }>

// Why a custom Vue plugin instead of turbo-mount's stock `turbo-mount/vue`:
// every island is its own Vue app, so each one needs the app-wide `pinia`
// singleton installed into its own createApp() before mounting. The stock
// plugin doesn't do that, so any registered component that calls a Pinia store
// (e.g. Download's useDownloadStore()) throws "no active Pinia". During the
// pilot this was masked by the previous mounter also running on the page and
// setting Pinia's activePinia global. Fix: wrap mounting so every component
// gets the same shared pinia via `app.use()`.
const piniaAwareVuePlugin: Plugin<Component> = {
  mountComponent({ el, Component: mounted, props }) {
    // turbo-mount types `props` as bare `object` (see MountComponentProps<T> in
    // turbo-mount's own .d.ts) — cast to match Vue's
    // createApp(component, props) signature.
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
 * page actually renders. Instead, scan the DOM for the
 * `turbo_mount(...)`-rendered host elements
 * that are actually present, read each one's real component name off its
 * `...-component-value` data attribute (turbo-mount kebab-cases that
 * attribute's NAME per component, but always keeps the PascalCase component
 * name as the VALUE — reading the value sidesteps needing to reimplement its
 * kebab-casing here), and only call that component's loader.
 *
 * A MutationObserver keeps watching after the initial scan: a turbo_mount div
 * can enter the DOM later — e.g. nested
 * inside another island's `v-html` prop (a raw ERB-rendered HTML string,
 * itself containing a turbo_mount call, injected into an already-mounted
 * component) — see RegionCountryPages' `relatedCountriesHtml` prop for a real
 * example of that pattern. Only register a given name once, even if its
 * host element appears more than once (turbo-mount throws on a duplicate
 * register).
 */
export function registerTurboMountComponents(map: Record<string, TurboMountLoader>): void {
  // Constructing this is safe because the module is evaluated exactly once per
  // page: without Turbo Drive there are no snapshot restores, so nothing can
  // pull in a second copy of the entrypoint bundle. That double evaluation used
  // to happen (CARRYOVER §8ab) and needed an idempotency guard here, because
  // TurboMount's constructor does `application.turboMount = this` and a second
  // instance left the first instance's already-registered controllers resolving
  // against an empty component map ("Unknown component: Map").
  const turboMount = new TurboMount()
  const inFlight = new Set<string>()
  // Collects only the mount promises triggered by the initial synchronous
  // scan below - see pdfReady.ts. Once those all settle we know every island
  // that was actually present at load has at least had its createApp().mount()
  // call run (Stimulus connects controllers synchronously on registration for
  // already-present elements), which is what markIslandScanComplete signals.
  const initialScanPromises: Promise<void>[] = []
  let trackingInitialScan = true

  function ensureRegistered(name: string): void {
    const loader = map[name]
    // A component name legitimately appears on several host elements on one
    // page; turbo-mount throws "Component 'X' is already registered." on the
    // second register, so skip anything already in its map.
    if (!loader || turboMount.components.has(name)) return
    // components.has() only turns true once the chunk resolves, so an in-flight
    // load needs its own guard: the MutationObserver below rescans on every DOM
    // change and would otherwise start the same import again.
    if (inFlight.has(name)) return
    inFlight.add(name)

    // The .catch matters: a component whose chunk 404s or throws at load time
    // otherwise fails silently -- the mount point just sits empty forever with
    // nothing in the console to explain why.
    const promise = loader()
      .then(mod => registerComponent(turboMount, name, mod.default))
      .catch(e => console.error(`[turboMount] failed to load component "${name}"`, e))
      .finally(() => inFlight.delete(name))

    if (trackingInitialScan) initialScanPromises.push(promise)
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
  trackingInitialScan = false
  Promise.all(initialScanPromises).then(markIslandScanComplete)

  if (typeof MutationObserver === 'undefined' || !document.documentElement) return
  // Observing <html> covers the whole document, including anything a script
  // appends outside <body>. Nothing replaces <html>, so one observer registered
  // here lasts the lifetime of the page.
  new MutationObserver((mutations) => {
    mutations.forEach(mutation =>
      mutation.addedNodes.forEach((node) => {
        if (node instanceof HTMLElement) scan(node)
      })
    )
  }).observe(document.documentElement, { childList: true, subtree: true })
}
