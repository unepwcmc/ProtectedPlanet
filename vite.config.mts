import { defineConfig } from 'vite'
import rails from 'vite-plugin-rails'

// Vite 7 + vite-plugin-rails (bundles vite-plugin-ruby + full-reload + compression),
// paired with the vite_ruby 3.x gem. Matches the pp-digital-report setup.
// Vue 3 support (@vitejs/plugin-vue) is added next, side-by-side with Webpacker's
// Vue 2 via an npm alias — see upgrade-plan/frontend/02-vite-on-rails-8.md.
export default defineConfig({
  plugins: [
    rails(),
  ],
})
