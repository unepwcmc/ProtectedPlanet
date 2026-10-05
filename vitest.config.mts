import { fileURLToPath } from 'node:url'
import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'
// Kept separate from vite.config.mts so tests don't load vite-plugin-rails
// (which expects the vite_ruby/Rails env).

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: [
      // Mirror vite.config.mts so specs can import components/types via `@/...`.
      { find: '@', replacement: fileURLToPath(new URL('./app/frontend', import.meta.url)) },
      // Mirror vite.config.mts so a component's `@reference "#importtailwindcss";` resolves
      // the same way under vitest as it does in the real Vite build.
      {
        find: /^#importtailwindcss$/,
        replacement: fileURLToPath(new URL('./app/frontend/styles/tailwind.css', import.meta.url)),
      },
    ],
  },
  test: {
    environment: 'jsdom',
    setupFiles: ['./vitest.setup.ts'],
    include: ['app/frontend/**/*.{test,spec}.{ts,js}'],
    server: {
      deps: {
        inline: [/@vue\/test-utils/, /@vueuse\//, /swiper/],
      },
    },
  },
})
