import { fileURLToPath } from 'node:url'
import { defineConfig } from 'vite'
import rails from 'vite-plugin-rails'
import tailwindcss from '@tailwindcss/vite'
import vue from '@vitejs/plugin-vue'
import checker from 'vite-plugin-checker'

// Values set via ViteRuby.env in config/vite.rb land in process.env here;
// only VITE_-prefixed ones are forwarded so Vite exposes them to client code
// as import.meta.env.VITE_* — see https://vite-ruby.netlify.app/guide/plugins.html#environment
const ViteEnvs: Record<string, string> = {}
for (const envKey of Object.keys(process.env)) {
  const envValue = process.env[envKey]
  if (envKey.includes('VITE_') && envValue !== undefined) {
        ViteEnvs[envKey] = envValue
  }
}

// Vite 7 + vite-plugin-rails, paired with the vite_ruby 3.x gem.
export default defineConfig({
  server: {
		// https://stackoverflow.com/questions/79372334/blocked-request-this-host-frontend-web-is-not-allowed
		// New breaking change for newer vite version
		allowedHosts: true
	}, 
  plugins: [
    rails({ envVars: { ...ViteEnvs } }),
    tailwindcss(),
    vue(),
    checker({ vueTsc: true /** or an object config */ })
  ],
  optimizeDeps: {
    // maplibre-gl ships its own worker as a separate chunk that the optimizer
    // doesn't handle correctly — pre-bundling 404s every request until excluded.
    exclude: ['maplibre-gl'],
    // pinia's own dist file statically imports devtools-api, which lazily
    // imports devtools-kit at runtime (on first app mount) — invisible to the
    // optimizer's static crawl, so it got discovered mid-request and stalled
    // every in-flight request ~20-25s while esbuild re-bundled. Including it
    // upfront pre-bundles it on cold start instead. (pinia itself used to be
    // excluded for a related resolve failure; removed 2026-08-19 after
    // confirming clean across a cold restart + cache clear.)
    include: ['@vue/devtools-kit'],
  },
  resolve: {
    alias: [
      // Lets any SFC <style> block write `@reference "#importtailwindcss";` and have it
      // resolve to OUR customised entry (preflight disabled, see that file) instead
      // of the npm package's default CSS. Documented Tailwind v4 + Vite pattern.
      // Exact-match regex only — subpaths like "tailwindcss/theme.css", which
      // app/frontend/styles/tailwind.css itself imports, must stay untouched.
      {
        find: /^#importtailwindcss$/,
        replacement: fileURLToPath(new URL('./app/frontend/styles/tailwind.css', import.meta.url)),
      },
    ],
  },
})
