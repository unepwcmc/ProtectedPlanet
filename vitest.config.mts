import { fileURLToPath } from 'node:url'
import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'
// Same Vue 2/Vue 3 coexistence trick as vite.config.mts: the main `vue` package is
// still 2.7 (Webpacker), so force plugin-vue + the `vue` import alias to Vue 3 for
// the island tests. Kept separate from vite.config.mts so tests don't load
// vite-plugin-rails (which expects the vite_ruby/Rails env).
import * as vue3Compiler from 'vue3/compiler-sfc'

export default defineConfig({
  plugins: [vue({ compiler: vue3Compiler })],
  resolve: {
    // Exact-match (regex) aliases so we don't accidentally rewrite `vue3/*` or
    // `@vue/test-utils/dist/*` sub-paths.
    alias: [
      // @vue/test-utils resolves to its CJS build under Node, whose `require('vue')`
      // escapes the vue->vue3 alias (picks up Vue 2.7, no createApp). Force the ESM
      // build so its `import ... from 'vue'` is transformed and aliased instead.
      {
        find: /^@vue\/test-utils$/,
        // Absolute path bypasses the package `exports` map, which otherwise blocks
        // reaching the ESM build directly.
        replacement: fileURLToPath(
          new URL(
            './node_modules/@vue/test-utils/dist/vue-test-utils.esm-bundler.mjs',
            import.meta.url
          )
        ),
      },
      { find: /^vue$/, replacement: 'vue3/dist/vue.esm-bundler.js' },
      // Mirror vite.config.mts so specs can import components/types via `@/...`.
      { find: '@', replacement: fileURLToPath(new URL('./app/frontend', import.meta.url)) },
      // Mirror vite.config.mts so a component's `@reference "tailwindcss";` resolves
      // the same way under vitest as it does in the real Vite build.
      {
        find: /^tailwindcss$/,
        replacement: fileURLToPath(new URL('./app/frontend/styles/tailwind.css', import.meta.url)),
      },
    ],
  },
  test: {
    environment: 'jsdom',
    include: ['app/frontend/**/*.{test,spec}.{ts,js}'],
    // Inline test-utils so Vite transforms it (applying the aliases above) instead
    // of loading it as an externalized dep via native import/require.
    server: {
      deps: {
        // @vueuse/core's and pinia's own `import ... from 'vue'` need the same
        // aliasing as @vue/test-utils above — inline them so Vite transforms them
        // instead of loading them as externalized deps that resolve 'vue' natively
        // (Vue 2.7).
        inline: [/@vue\/test-utils/, /@vueuse\//, /pinia/],
      },
    },
  },
})
