//= require vue
//= require d3
//= require vue/charts/Sunburst
//= require vue/charts/Treemap
//= require vue/test/Incrementor

new Vue({
  el: '.v-marine',
  components: {
    'sunburst': VComponents['vue/charts/Sunburst'],
    'treemap': VComponents['vue/charts/Treemap'],
    'incrementor': VComponents['vue/test/Incrementor']
  }
})

