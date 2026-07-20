import { defineConfig } from 'vite'
import rails from 'vite-plugin-rails'
import vue from '@vitejs/plugin-vue'
// Force plugin-vue to use Vue 3's compiler even though the main `vue` package is
// still 2.7 (Webpacker/vue-loader 15 needs 2.7). `vue3` is an npm alias for vue@3.
// This is what lets Vite/Vue 3 and Webpacker/Vue 2 coexist without touching Webpacker.
import * as vue3Compiler from 'vue3/compiler-sfc'

// Vite 7 + vite-plugin-rails, paired with the vite_ruby 3.x gem.
export default defineConfig({
  plugins: [
    rails(),
    vue({ compiler: vue3Compiler }),
  ],
  resolve: {
    alias: {
      // Vite bundles Vue 3 (runtime + compiler). Does NOT affect Webpacker's webpack.
      vue: 'vue3/dist/vue.esm-bundler.js',
    },
  },
})
