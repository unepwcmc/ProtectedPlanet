const { defineConfig } = require('vite')
const RubyPlugin = require('vite-plugin-ruby').default

module.exports = defineConfig({
  plugins: [RubyPlugin()],
})
