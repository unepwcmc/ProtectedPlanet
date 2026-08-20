// Single shared Pinia instance for every island. lib/turboMount.ts's Vue plugin
// installs it into each island's own createApp() (islands are separate Vue apps,
// not one tree), so stores defined with defineStore() are shared across islands
// as long as they all resolve useXStore() against this same instance.
import { createPinia } from 'pinia'

export const pinia = createPinia()
