// Single shared Pinia instance for every island. lib/turboMount.ts's Vue plugin
// installs it into each island's own createApp() (islands are separate Vue apps,
// not one tree), so any store defined with defineStore() is shared across
// islands as long as they all resolve useXStore() against this same instance.
//
// NOTHING USES IT YET — it is wired up and ready, not dead by accident.
//
// The one store this app had (the download queue) turned out not to need Pinia:
// localStorage is that feature's source of truth, so `useStorage` already
// provided the shared reactive state, and Pinia's singleton added nothing on top
// of a module-level one. It now lives in composables/useDownloads.ts.
//
// So reach for Pinia when a feature has genuinely shared *in-memory* state that
// several islands mutate — where you want devtools, named actions and a
// per-instance lifecycle. For state that a browser storage already owns, or that
// one island owns alone, a composable is the simpler answer.
import { createPinia } from 'pinia'

export const pinia = createPinia()
