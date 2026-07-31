import { fileURLToPath } from 'node:url'
import { defineConfig } from 'vite'
import rails from 'vite-plugin-rails'
import tailwindcss from '@tailwindcss/vite'
import vue from '@vitejs/plugin-vue'

// Values set via ViteRuby.env in config/vite.rb land in process.env here;
// only VITE_-prefixed ones are forwarded so Vite exposes them to client code
// as import.meta.env.VITE_* — see https://vite-ruby.netlify.app/guide/plugins.html#environment
const ViteEnvs: Record<string, unknown> = {}
for (const envKey of Object.keys(process.env)) {
  if (envKey.includes('VITE_')) ViteEnvs[envKey] = process.env[envKey]
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
  ],
  optimizeDeps: {
    // maplibre-gl ships its own worker as a separate chunk (maplibre-gl-worker.mjs)
    // that the dev-server optimizer doesn't handle correctly — pre-bundling it
    // produces a reference to a deps-cache file that never actually gets written,
    // 404ing every request until excluded.
    exclude: ['maplibre-gl'],
  },
  resolve: {
    alias: [
      // Lets any SFC <style> block write `@reference "tailwindcss";` and have it
      // resolve to OUR customised entry (preflight disabled, see that file) instead
      // of the npm package's default CSS. Documented Tailwind v4 + Vite pattern.
      // Exact-match regex only — subpaths like "tailwindcss/theme.css", which
      // app/frontend/styles/tailwind.css itself imports, must stay untouched.
      {
        find: /^tailwindcss$/,
        replacement: fileURLToPath(new URL('./app/frontend/styles/tailwind.css', import.meta.url)),
      },
    ],
  },
})
