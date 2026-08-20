// TurboMount wiring for the `turbo_mount` ERB helper (see the "turbo-mount
// spike result" memory / upgrade-plan/frontend/14-architecture-and-design.md).
// Loaders are lazy (`() => import(...)`), same as islands.ts's IslandLoader —
// see below for why a DOM scan (not just calling every loader up front) is
// needed to actually keep that laziness.
import { TurboMount, buildRegisterFunction, type ApplicationWithTurboMount, type Plugin } from 'turbo-mount'
import { createApp, type Component } from 'vue'
import { pinia } from '@/stores/pinia'
import { markIslandScanComplete } from '@/lib/pdfReady'

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
  // Reuse an existing instance rather than always constructing one.
  //
  // TurboMount's constructor does `application.turboMount = this`, and its
  // controllers resolve components through THAT pointer:
  //
  //   resolve(name) { const c = this.components.get(name); if (!c) throw `Unknown component: ${name}` }
  //
  // So if this entrypoint is evaluated twice — which happens when Turbo Drive
  // restores a page whose <head> references a previous deploy's application-*.js
  // and pulls in a second bundle — instance B replaces A on the shared Stimulus
  // application while A's controllers are already registered. Those controllers
  // then resolve against B's EMPTY component map and throw
  // "Unknown component: Map" / "Unknown component: Download" on connect.
  //
  // data-turbo-track="reload" in the layout stops the double-load itself; this
  // makes the module idempotent regardless of why it runs twice.
  // window.Stimulus is typed as a plain Application; turbo-mount's own
  // ApplicationWithTurboMount is the interface that exposes the attached instance.
  const turboMount = (window.Stimulus as ApplicationWithTurboMount | undefined)?.turboMount
    ?? new TurboMount()
  const inFlight = new Set<string>()
  // Collects only the mount promises triggered by the initial synchronous
  // scan below - see pdfReady.ts. Once those all settle we know every island
  // that was actually present at load has at least had its createApp().mount()
  // call run (Stimulus connects controllers synchronously on registration for
  // already-present elements), which is what markIslandScanComplete signals.
  // On a second evaluation of this module every component is already registered,
  // so nothing is collected and the flag flips on the next microtask — correct,
  // since those islands are already mounted.
  const initialScanPromises: Promise<void>[] = []
  let trackingInitialScan = true

  function ensureRegistered(name: string): void {
    const loader = map[name]
    // Ask the shared instance, not a per-call Set: a second evaluation of this
    // module gets a fresh Set but the same TurboMount, and re-registering throws
    // "Component 'X' is already registered."
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
  // Observe <html>, not <body>: Turbo Drive replaces the whole <body> element
  // on navigation (it doesn't just mutate its children), so an observer bound
  // to the original document.body would keep watching a detached node after
  // the first Turbo visit and miss every turbo_mount host on later pages.
  // <html> itself is never replaced, so this survives both a full body swap
  // and Turbo 8's in-place morph render.
  new MutationObserver((mutations) => {
    mutations.forEach(mutation =>
      mutation.addedNodes.forEach((node) => {
        if (node instanceof HTMLElement) scan(node)
      })
    )
  }).observe(document.documentElement, { childList: true, subtree: true })
}
