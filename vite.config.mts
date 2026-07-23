import { fileURLToPath } from 'node:url'
import { defineConfig } from 'vite'
import rails from 'vite-plugin-rails'
import tailwindcss from '@tailwindcss/vite'
import vue from '@vitejs/plugin-vue'
// Force plugin-vue to use Vue 3's compiler even though the main `vue` package is
// still 2.7 (Webpacker/vue-loader 15 needs 2.7). `vue3` is an npm alias for vue@3.
// This is what lets Vite/Vue 3 and Webpacker/Vue 2 coexist without touching Webpacker.
import * as vue3Compiler from 'vue3/compiler-sfc'

// Vite 7 + vite-plugin-rails, paired with the vite_ruby 3.x gem.
export default defineConfig({
  server: {
		// https://stackoverflow.com/questions/79372334/blocked-request-this-host-frontend-web-is-not-allowed
		// New breaking change for newer vite version
		allowedHosts: true
	},
  plugins: [
    rails(),
    tailwindcss(),
    vue({ compiler: vue3Compiler }),
  ],
  optimizeDeps: {
    // @vueuse/core and pinia import Vue3-only exports (Fragment, toValue,
    // hasInjectionContext, ...) that don't exist on the real `vue` (2.7)
    // package. The dev-server dependency pre-bundler doesn't consistently
    // apply the `vue` -> `vue3` alias below to their internal `import ...
    // from 'vue'`, causing a hard crash on cold start / re-optimization.
    // Excluding them from pre-bundling defers resolution to Vite's normal
    // per-request transform, where the alias does apply.
    exclude: ['@vueuse/core', 'pinia'],
  },
  resolve: {
    alias: [
      // Vite bundles Vue 3 (runtime + compiler). Does NOT affect Webpacker's webpack.
      { find: 'vue', replacement: 'vue3/dist/vue.esm-bundler.js' },
      // Component code imports as `@/components/...`, never relative `../../`.
      { find: '@', replacement: fileURLToPath(new URL('./app/frontend', import.meta.url)) },
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
