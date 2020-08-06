const { environment } = require('@rails/webpacker')
const { VueLoaderPlugin } = require('vue-loader')
const vue = require('./loaders/vue')
const DotenvPlugin = require('dotenv-webpack')

environment.plugins.prepend('DotenvPlugin', new DotenvPlugin())
environment.plugins.prepend('VueLoaderPlugin', new VueLoaderPlugin())
environment.loaders.prepend('vue', vue)
module.exports = environment
