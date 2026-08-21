// The app's only island mounter, backing the `turbo_mount` ERB helper.
import { TurboMount, buildRegisterFunction, type Plugin } from 'turbo-mount'
import { createApp, type Component } from 'vue'
import { pinia } from '@/stores/pinia'
import { markIslandScanComplete } from '@/lib/pdfReady'

export type TurboMountLoader = () => Promise<{ default: Component }>

// Replaces turbo-mount's stock `turbo-mount/vue` plugin, which doesn't install
// anything into the per-island createApp(). Without the shared pinia, any
// component using a store throws "no active Pinia".
//
// No component uses a store today (see stores/pinia.ts) — this stays so that the
// first one to need it works without having to rediscover why the stock plugin
// isn't enough.
const piniaAwareVuePlugin: Plugin<Component> = {
  mountComponent({ el, Component: mounted, props }) {
    // turbo-mount types `props` as bare `object`; cast to createApp's signature.
    const app = createApp(mounted, props as Parameters<typeof createApp>[1])
    app.use(pinia)
    app.mount(el)
    return () => app.unmount()
  }
}

const registerComponent = buildRegisterFunction(piniaAwareVuePlugin)

const TURBO_MOUNT_SELECTOR = '[data-controller^="turbo-mount-"]'

/**
 * Register component name -> lazy loader for turbo-mount.
 *
 * Only the loaders for hosts actually on the page are called — calling all of
 * them up front would download every component's chunk on every page. Each
 * host's PascalCase name is read off its `...-component-value` data attribute,
 * whose value turbo-mount leaves un-kebab-cased.
 *
 * A MutationObserver keeps scanning afterwards: a turbo_mount div can arrive
 * later inside another island's `v-html` prop — see RegionCountryPages'
 * `relatedCountriesHtml`.
 */
export function registerTurboMountComponents(map: Record<string, TurboMountLoader>): void {
  // One instance is safe: without Turbo Drive the module is evaluated exactly
  // once per page. A second TurboMount would overwrite `application.turboMount`
  // and leave the first's controllers resolving against an empty component map.
  const turboMount = new TurboMount()
  const inFlight = new Set<string>()
  // Mount promises from the initial synchronous scan only. Once they settle,
  // every island present at load has run its mount (Stimulus connects
  // already-present elements synchronously) — that's what pdfReady waits on.
  const initialScanPromises: Promise<void>[] = []
  let trackingInitialScan = true

  function ensureRegistered(name: string): void {
    const loader = map[name]
    // One name can have several hosts, and turbo-mount throws on re-register.
    if (!loader || turboMount.components.has(name)) return
    // components.has() only turns true once the chunk resolves, so in-flight
    // loads need their own guard against the MutationObserver's rescans.
    if (inFlight.has(name)) return
    inFlight.add(name)

    // Without the .catch a chunk that 404s leaves the mount point silently empty.
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
  // <html> is never replaced, so one observer here covers the whole page life.
  new MutationObserver((mutations) => {
    mutations.forEach(mutation =>
      mutation.addedNodes.forEach((node) => {
        if (node instanceof HTMLElement) scan(node)
      })
    )
  }).observe(document.documentElement, { childList: true, subtree: true })
}
